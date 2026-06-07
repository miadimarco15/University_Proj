library(MASS)
library(dplyr)
library(tidyr)
library(ggplot2)
library(ggrepel)
library(glmnet)
library(lmtest)

library(conflicted)
conflict_prefer("select", "dplyr")
conflict_prefer("filter", "dplyr")
conflict_prefer("lag", "dplyr")

patents <- read.csv("SYB67_264_202411_Patents.csv")
population_growth <- read.csv("SYB61_253_Population Growth Rates in Urban areas and Capital cities.csv")
population_density <- read.csv("SYB67_1_202411_Population, Surface Area and Density.csv")
GDP <- read.csv("SYB67_230_202411_GDP and GDP Per Capita.csv")
RandD_expenditure <- read.csv("SYB67_285_202411_Research and Development Expenditure and Staff.csv")
internet_usage <- read.csv("SYB67_314_202411_Internet Usage.csv")

#####dataset
patents_2022 <- patents %>%
  filter(X == 2022, X.1 == 'Resident patent filings (per million population)') %>%
  select(
    Country = Patents,
    Patents = X.2)

population_growth_2018 <- population_growth %>%
  filter(X == 2018, X.1 == "Urban population (percent)") %>%
  select(
    Country = `Population.and.rates.of.growth.in.urban.areas.and.capital.cities`,
    Urban_perc = X.4
  )

over60_2022 <- population_density %>%
  filter(X == 2022,
         X.1 == "Population aged 60+ years old (percentage)") %>%   
  select(
    Country = `Population..density.and.surface.area`,             
    Over60 = X.2                    
  )

population_density_2022 <- population_density %>%
  filter(X == 2022,
         X.1 == "Population density") %>%   
  select(
    Country = `Population..density.and.surface.area`,             
    Density = X.2                    
  )

GDP_2022 <- GDP %>% filter(X == 2022, X.1 == 'GDP per capita (US dollars)') %>%
  select(
    Country = Gross.domestic.product.and.gross.domestic.product.per.capita,
    GDP = X.2
  )

internet_usage_2022 <- internet_usage %>% filter(X == 2022, X.1 == 'Percentage of individuals using the internet') %>%
  select(
    Country = Internet.Usage,
    Internet_perc = X.2
  )

RandD_expenditure_2022 <- RandD_expenditure %>% 
  filter(
    X %in% c(2018, 2019, 2020, 2021, 2022),
    X.1 == "Gross domestic expenditure on R&D: as a percentage of GDP"
  ) %>%
  arrange(
    `Research.and.development..R.D..expenditure.and.researchers..full.time.equivalent.`,
    desc(X)
  ) %>%
  distinct(
    `Research.and.development..R.D..expenditure.and.researchers..full.time.equivalent.`,
    .keep_all = TRUE
  ) %>%
  select(
    Country = Research.and.development..R.D..expenditure.and.researchers..full.time.equivalent.,
    RandD = X.2
  )

Researchers_2022 <- RandD_expenditure %>% 
  filter(
    X %in% c(2020, 2021, 2022),
    X.1 == "Researchers per million inhabitants (FTE)"
  ) %>%
  arrange(
    `Research.and.development..R.D..expenditure.and.researchers..full.time.equivalent.`,
    desc(X)
  ) %>%
  distinct(
    `Research.and.development..R.D..expenditure.and.researchers..full.time.equivalent.`,
    .keep_all = TRUE
  ) %>%
  select(
    Country = Research.and.development..R.D..expenditure.and.researchers..full.time.equivalent.,
    Researchers = X.2
  )

dataset <- patents_2022 %>%
  left_join(GDP_2022,                by = "Country") %>%
  left_join(population_density_2022, by = "Country") %>%
  left_join(population_growth_2018,  by = "Country") %>%
  left_join(internet_usage_2022,     by = "Country") %>%
  left_join(RandD_expenditure_2022,  by = "Country") %>%
  left_join(Researchers_2022,        by = "Country") %>%
  left_join(over60_2022,             by = "Country")

dataset <- dataset %>%
  mutate(across(-Country, ~ as.numeric(gsub(",", "", .)))) %>%
  mutate(log_patents = log(Patents + 1)) %>%
  mutate(log_Density = log(Density + 1))

####Box-Cox lambda calc
df_bc <- dataset %>%
  select(Patents, GDP, Urban_perc, Internet_perc, RandD, Researchers, Over60, log_Density) %>%
  drop_na() %>%
  mutate(Patents_bc = Patents + 1)  

m_bc <- lm(Patents_bc ~ GDP + Urban_perc + Internet_perc + RandD +
             Researchers + Over60 + log_Density,
           data = df_bc)

bc <- MASS::boxcox(m_bc, lambda = seq(-2, 2, by = 0.05), plotit = FALSE)
lambda_hat <- bc$x[which.max(bc$y)]
lambda_hat

#####Patents distribution vs log_patents distribution
hist(dataset$Patents,
       main = "Number of patents distribution",
       xlab = "Number of patents",
       ylab = "Frequency",
       col = "darkblue",
       border = "white",
       breaks = 100)
  
hist(dataset$log_patents,
       main = "Number of patents, logarithmic distribution",
       xlab = "log(Patents + 1)",
       ylab = "Frequency",
       col = "darkblue",
       border = "white",
       breaks = 40)

####scatter plot + t test 
hist(dataset$Density,
     main = "Density distribution",
     xlab = "Density",
     ylab = "Frequency",
     col = "darkblue",
     border = "white",
     breaks = 80)

predictors <- setdiff(names(dataset), c("Country", "Patents", "log_patents"))
for (var in predictors) {
    plot_pred <- dataset %>%
      select(Country, log_patents, pred = all_of(var)) %>%
      filter(!is.na(log_patents), !is.na(pred))
    
    if (nrow(plot_pred) < 5) next

    m <- lm(log_patents ~ pred, data = plot_pred)
    sm <- summary(m)
    
    beta <- sm$coefficients["pred", "Estimate"]
    tval <- sm$coefficients["pred", "t value"]
    pval <- sm$coefficients["pred", "Pr(>|t|)"]
    r2   <- sm$r.squared
    
    corr <- cor(plot_pred$log_patents, plot_pred$pred, use = "complete.obs")
    
    p <- ggplot(plot_pred, aes(x = pred, y = log_patents)) +
      geom_point(alpha = 0.6) +
      geom_smooth(method = "lm", se = FALSE, color = "darkblue") +
      labs(
        title = paste("log(Patents + 1) vs", var),
        subtitle = paste0(
          "corr = ", round(corr, 3),
          " | beta = ", round(beta, 3),
          " | t = ", round(tval, 2),
          " | p = ", signif(pval, 3),
          " | R² = ", round(r2, 3)
        ),
        x = var,
        y = "log(Patents + 1)"
      ) +
      theme_minimal(base_size = 13)
    cat("p-value =", signif(pval, 3), "\n")
    print(p)
}

####R^2 calc
r <- lm(log_patents ~ GDP + Internet_perc + RandD + Researchers + Over60 + Urban_perc + log_Density,
        data = dataset)

X <- model.matrix(r)[, -1, drop = FALSE]

X <- scale(X)

R2_j <- sapply(seq_len(ncol(X)), function(j) {
  yj <- X[, j]
  Xo <- X[, -j, drop = FALSE]
  fit <- lm.fit(x = cbind(1, Xo), y = yj)
  rss <- sum(fit$residuals^2)
  tss <- sum((yj - mean(yj))^2)
  1 - rss/tss
})

R2_table <- data.frame(
  Variable = colnames(X),
  R2_against_others = as.numeric(R2_j)
) %>%
  arrange(desc(R2_against_others))

print(R2_table)



####MODEL SELECTION 
  set.seed(1)
  
  reduced <- dataset %>% select(-Country, -Patents, -Density) %>% drop_na()
  
  rmse <- function(y, yhat) sqrt(mean((y - yhat)^2))
  
  B <- 200
  train_frac <- 0.8
  K <- 10
  alphas <- seq(0, 1, by = 0.1)
  
  out <- vector("list", B)
  X_all <- model.matrix(log_patents ~ ., data = reduced)[, -1, drop = FALSE]
  y_all <- reduced$log_patents
  
  n <- nrow(reduced)
  for (b in 1:B) {
    idx <- sample(seq_len(n), size = floor(train_frac * n))
    train <- reduced[idx, ]
    test  <- reduced[-idx, ]
    
    X_train <- X_all[idx, , drop = FALSE]
    y_train <- y_all[idx]
    
    X_test  <- X_all[-idx, , drop = FALSE]
    y_test  <- y_all[-idx]
    
    m_ols <- lm(log_patents ~ ., data = train)
    pred_ols <- predict(m_ols, newdata = test)
    rmse_ols <- rmse(y_test, pred_ols)
    
    # Ridge (alpha=0)
    cv_ridge <- cv.glmnet(X_train, y_train, alpha = 0, nfolds = K, standardize = TRUE)
    pred_ridge <- as.numeric(predict(cv_ridge, newx = X_test, s = "lambda.min"))
    rmse_ridge <- rmse(y_test, pred_ridge)
    
    # LASSO (alpha=1)
    cv_lasso <- cv.glmnet(X_train, y_train, alpha = 1, nfolds = K, standardize = TRUE)
    pred_lasso <- as.numeric(predict(cv_lasso, newx = X_test, s = "lambda.min"))
    rmse_lasso <- rmse(y_test, pred_lasso)
    
    # Elastic Net
    cv_list <- lapply(alphas, function(a) {
      cv <- cv.glmnet(X_train, y_train, alpha = a, nfolds = K, standardize = TRUE)
      list(alpha = a, cv = cv, mincvm = min(cv$cvm))
    })
    best_i <- which.min(sapply(cv_list, `[[`, "mincvm"))
    best_alpha <- cv_list[[best_i]]$alpha
    cv_en <- cv_list[[best_i]]$cv
    
    pred_en <- as.numeric(predict(cv_en, newx = X_test, s = "lambda.min"))
    rmse_en <- rmse(y_test, pred_en)
    
    out[[b]] <- data.frame(
      split = b,
      OLS = rmse_ols,
      Ridge = rmse_ridge,
      LASSO = rmse_lasso,
      ElasticNet = rmse_en,
      best_alpha = best_alpha
    )
  }
  
  res <- bind_rows(out)
  
  summary_rmse <- res %>%
    summarise(across(c(Ridge, LASSO, ElasticNet, OLS),
                     list(mean = mean, sd = sd)))
  print(summary_rmse)
  
  
  wins <- apply(res[, c("Ridge", "LASSO", "ElasticNet", "OLS")], 1, function(x) names(which.min(x)))
  print(table(wins))
  
  cat("\nShare of splits where Ridge RMSE < OLS RMSE: ",
      mean(res$Ridge < res$OLS), "\n", sep = "")
  
  res_long <- res %>%
    select(split, OLS, Ridge, LASSO, ElasticNet) %>%
    tidyr::pivot_longer(-split, names_to = "Model", values_to = "RMSE")
  
  ggplot(res_long, aes(x = Model, y = RMSE)) +
    geom_boxplot(outlier.alpha = 0.3) +
    labs(title = "Test RMSE across 200 random 80/20 splits",
       x = "", y = "RMSE (test set)") +
  theme_minimal(base_size = 13)

X_all <- model.matrix(log_patents ~ ., data = reduced)[, -1, drop = FALSE]
y_all <- reduced$log_patents

cv_ridge_final <- cv.glmnet(X_all, y_all, alpha = 0, nfolds = 10, standardize = TRUE)
yhat_all <- as.numeric(predict(cv_ridge_final, newx = X_all, s = "lambda.min"))
pred_df <- data.frame(observed = y_all, predicted = yhat_all)

ggplot(pred_df, aes(x = observed, y = predicted)) +
  geom_point(alpha = 0.7) +
  geom_abline(slope = 1, intercept = 0, linetype = "dashed") +
  labs(title = "Ridge regression: predicted vs observed",
       x = "Observed log(Patents + 1)",
       y = "Predicted log(Patents + 1)") +
  theme_minimal(base_size = 13)

X_all <- model.matrix(log_patents ~ ., data = reduced)[, -1, drop = FALSE]
y_all <- reduced$log_patents

cv_ridge_final <- cv.glmnet(X_all, y_all, alpha = 0, nfolds = 10, standardize = TRUE)

lambda_min_final <- cv_ridge_final$lambda.min
cat("Final Ridge lambda.min:", lambda_min_final, "\n")

beta_ridge_final <- as.matrix(coef(cv_ridge_final, s = "lambda.min"))
print(beta_ridge_final)

####REGRESSION DIAGNOSTICS
m_diag <- lm(log_patents ~ GDP + Urban_perc + Internet_perc + RandD +
               Researchers + Over60 + log_Density,
             data = reduced) 

res <- residuals(m_diag)
fit <- fitted(m_diag)

shap <- shapiro.test(res)
bp   <- bptest(m_diag)

cat("\nShapiro-Wilk test for normality of residuals:\n")
print(shap)

cat("\nBreusch-Pagan test for heteroskedasticity:\n")
print(bp)

plot(fit, res,
     xlab = "Fitted values",
     ylab = "Residuals",
     main = "Residuals vs Fitted")
abline(h = 0, lty = 2)

qqnorm(res, main = "Normal Q-Q plot of residuals")
qqline(res, col = "darkblue", lwd = 2)

hist(res,
     breaks = "FD",         
     probability = TRUE,
     main = "Residuals histogram (with normal curve)",
     xlab = "Residuals",
     col = "lightgray",
     border = "white")

curve(dnorm(x, mean = mean(res), sd = sd(res)),
      add = TRUE, col = "darkblue", lwd = 2)

####Welch 2 sample t-test
test_data = dataset %>% select(log_patents, Urban_perc) %>% drop_na()

median_urban = median(test_data$Urban_perc)
test_data = test_data %>% mutate(
  Urban_group = ifelse(Urban_perc > median_urban,
                       "High urbanization", 
                       "Low urbanization"))
t_test_urban = t.test(
  log_patents ~ Urban_group,
  data = test_data,
  alternative = "greater")
print(t_test_urban)