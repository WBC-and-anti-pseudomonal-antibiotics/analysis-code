# Load required libraries
library(AER)            # for ivreg
library(sandwich)       # for robust standard errors
library(lmtest)         # for coeftest and waldtest
library(glmnet)         # for LASSO logistic regression
library(randomForest)   # for random forest
library(pROC)           # for AUC
library(caret)          # for cross‑validation metrics

# Read the data
df <- read.csv("HTE_df.csv")

# Create interaction between treatment and WBC
df$T_WBC <- df$Piperacillin_tazobactam * df$wbc
df$Z_WBC <- df$instrument * df$wbc

# Define covariates used throughout the models
covars <- c("wbc", "decade", "SOFA", "charlson_score", "time_to_rx", "female", "non_white")

# Drop observations with missing values in key variables
df_complete <- df[complete.cases(df[, c("Piperacillin_tazobactam", "instrument", "die_within_30d", covars)]), ]

# ---- First-stage logistic regression (treatment model) ----
first_stage_glm <- glm(Piperacillin_tazobactam ~ instrument + wbc + decade + SOFA + charlson_score + time_to_rx + female + non_white,
                       data = df_complete, family = binomial())
summary(first_stage_glm)

# Wald test for instrument in the logistic first stage
wald_z <- coef(first_stage_glm)["instrument"] / sqrt(vcov(first_stage_glm)["instrument", "instrument"])
wald_p <- 2 * (1 - pnorm(abs(wald_z)))
cat("\nWald test for instrument (logistic first stage): z =", round(wald_z, 3), "p-value =", signif(wald_p, 3), "\n")

# ---- First-stage linear probability model ----
first_stage_lm <- lm(Piperacillin_tazobactam ~ instrument + wbc + decade + SOFA + charlson_score + time_to_rx + female + non_white,
                     data = df_complete)
summary(first_stage_lm)

# Partial F-statistic for instrument in linear first stage
lm_reduced <- lm(Piperacillin_tazobactam ~ wbc + decade + SOFA + charlson_score + time_to_rx + female + non_white,
                 data = df_complete)
anova_res <- anova(lm_reduced, first_stage_lm)
cat("\nPartial F-test for instrument (linear first stage): F =", anova_res$F[2], "df1 =", anova_res$Df[2], "df2 =", anova_res$Df[1],
    "p-value =", anova_res$`Pr(>F)`[2], "\n")

# ---- Instrumental variable model: two-stage least squares ----
# Formulate the IV regression with treatment and treatment*WBC as endogenous variables instrumented by instrument and instrument*WBC.
iv_formula <- as.formula(paste(
  "die_within_30d ~ Piperacillin_tazobactam + T_WBC +", paste(covars, collapse = " + "), "| instrument + Z_WBC +", paste(covars, collapse = " + ")
))
iv_model <- ivreg(iv_formula, data = df_complete)
summary(iv_model, diagnostics = TRUE)

# Extract first-stage regressions from ivreg object
fs_summary <- iv_model$fit$first
cat("\nFirst-stage results from ivreg:\n")
print(fs_summary)

# ---- Exclusion restriction test ----
# Outcome model including treatment, covariates and instrument
excl_model <- glm(die_within_30d ~ instrument + Piperacillin_tazobactam + wbc + decade + SOFA + charlson_score + time_to_rx + female + non_white,
                  data = df_complete, family = binomial())
excl_coef <- summary(excl_model)$coefficients["instrument", ]
cat("\nExclusion restriction test (instrument coefficient): coef =", round(excl_coef[1], 4), "SE =", round(excl_coef[2], 4),
    "z =", round(excl_coef[3], 3), "p =", signif(excl_coef[4], 3), "\n")

# ---- Independence assessment ----
# Standardised mean differences by instrument for covariates
smd <- sapply(covars, function(var) {
  grp0 <- df_complete[df_complete$instrument == 0, var]
  grp1 <- df_complete[df_complete$instrument == 1, var]
  mean1 <- mean(grp1, na.rm = TRUE); mean0 <- mean(grp0, na.rm = TRUE)
  sd_pooled <- sqrt((var(grp0, na.rm = TRUE) + var(grp1, na.rm = TRUE)) / 2)
  (mean1 - mean0) / sd_pooled
})
cat("\nStandardised mean differences by instrument:\n")
print(round(smd, 3))

# Regression of IV residuals on instrument (overidentification-like test)
fs_fitted <- fitted(iv_model)
residuals_iv <- df_complete$die_within_30d - fs_fitted
resid_test <- lm(residuals_iv ~ instrument + wbc + decade + SOFA + charlson_score + time_to_rx + female + non_white,
                 data = df_complete)
resid_test_reduced <- lm(residuals_iv ~ wbc + decade + SOFA + charlson_score + time_to_rx + female + non_white,
                         data = df_complete)
anova_resid <- anova(resid_test_reduced, resid_test)
cat("\nRegression of IV residuals on instrument: F =", anova_resid$F[2], "p-value =", anova_resid$`Pr(>F)`[2], "\n")

# ---- Durbin-Wu-Hausman test ----
# Fit ordinary least squares model with observed treatment and interaction
ols_formula <- as.formula(paste(
  "die_within_30d ~ Piperacillin_tazobactam + T_WBC +", paste(covars, collapse = " + ")
))
ols_model <- lm(ols_formula, data = df_complete)

# Hausman statistic using vcov difference
coef_ols <- coef(ols_model)[c("Piperacillin_tazobactam", "T_WBC")]
coef_iv <- coef(iv_model)[c("Piperacillin_tazobactam", "T_WBC")]
cov_ols <- vcovHC(ols_model, type = "HC1")[c("Piperacillin_tazobactam", "T_WBC"), c("Piperacillin_tazobactam", "T_WBC")]
cov_iv <- vcovHC(iv_model, type = "HC1")[c("Piperacillin_tazobactam", "T_WBC"), c("Piperacillin_tazobactam", "T_WBC")]

b_diff <- coef_ols - coef_iv
cov_diff <- cov_iv - cov_ols
h_stat <- t(b_diff) %*% solve(cov_diff) %*% b_diff
hausman_p <- 1 - pchisq(h_stat, df = length(b_diff))
cat("\nDurbin–Wu–Hausman test: statistic =", as.numeric(h_stat), "p-value =", as.numeric(hausman_p), "\n")

# ---- Predictive models for risk modelling ----
# Set up predictor matrix
X_mat <- as.matrix(df_complete[, c("Piperacillin_tazobactam", "T_WBC", covars)])
y_vec <- df_complete$die_within_30d

# Cross-validation folds
set.seed(123)
folds <- createFolds(y_vec, k = 3, list = TRUE, returnTrain = FALSE)

# Function to compute metrics
compute_metrics <- function(truth, probs) {
  logloss <- -mean(truth * log(pmax(probs, 1e-15)) + (1 - truth) * log(pmax(1 - probs, 1e-15)))
  auc_val <- as.numeric(roc(truth, probs)$auc)
  brier <- mean((truth - probs)^2)
  c(logloss = logloss, auc = auc_val, brier = brier)
}

# Logistic regression
metrics_logit <- matrix(NA, nrow = length(folds), ncol = 3)
for (i in seq_along(folds)) {
  idx <- folds[[i]]
  trainX <- X_mat[-idx, ]
  trainY <- y_vec[-idx]
  testX <- X_mat[idx, ]
  testY <- y_vec[idx]
  mod <- glm(trainY ~ trainX, family = binomial())
  pred <- predict(mod, newdata = data.frame(trainX = testX), type = "response")
  metrics_logit[i, ] <- compute_metrics(testY, pred)
}
mean_metrics_logit <- colMeans(metrics_logit)

# LASSO logistic
metrics_lasso <- matrix(NA, nrow = length(folds), ncol = 3)
for (i in seq_along(folds)) {
  idx <- folds[[i]]
  x_train <- X_mat[-idx, ]
  x_test <- X_mat[idx, ]
  y_train <- y_vec[-idx]
  y_test <- y_vec[idx]
  cv_fit <- cv.glmnet(x = x_train, y = y_train, family = "binomial", alpha = 1, nfolds = 3)
  probs <- predict(cv_fit, newx = x_test, s = "lambda.min", type = "response")
  metrics_lasso[i, ] <- compute_metrics(y_test, probs)
}
mean_metrics_lasso <- colMeans(metrics_lasso)

# Random forest
metrics_rf <- matrix(NA, nrow = length(folds), ncol = 3)
for (i in seq_along(folds)) {
  idx <- folds[[i]]
  x_train <- df_complete[-idx, c("Piperacillin_tazobactam", "T_WBC", covars)]
  x_test <- df_complete[idx, c("Piperacillin_tazobactam", "T_WBC", covars)]
  y_train <- y_vec[-idx]
  y_test <- y_vec[idx]
  rf_fit <- randomForest(x = x_train, y = as.factor(y_train), ntree = 200, mtry = 3)
  probs <- predict(rf_fit, newdata = x_test, type = "prob")[, 2]
  metrics_rf[i, ] <- compute_metrics(y_test, probs)
}
mean_metrics_rf <- colMeans(metrics_rf)

cat("\nCross‑validated performance:\n")
cat("Logistic regression: logloss", round(mean_metrics_logit["logloss"], 3), "AUC", round(mean_metrics_logit["auc"], 3), "Brier", round(mean_metrics_logit["brier"], 3), "\n")
cat("LASSO logistic regression: logloss", round(mean_metrics_lasso["logloss"], 3), "AUC", round(mean_metrics_lasso["auc"], 3), "Brier", round(mean_metrics_lasso["brier"], 3), "\n")
cat("Random forest: logloss", round(mean_metrics_rf["logloss"], 3), "AUC", round(mean_metrics_rf["auc"], 3), "Brier", round(mean_metrics_rf["brier"], 3), "\n")

# Random forest variable importance
rf_final <- randomForest(x = df_complete[, c("Piperacillin_tazobactam", "T_WBC", covars)], y = as.factor(y_vec), ntree = 300, mtry = 3)
importance_vals <- importance(rf_final, type = 2)
importance_df <- data.frame(Predictor = rownames(importance_vals), Importance = importance_vals[, 1])
print(importance_df[order(-importance_df$Importance), ])