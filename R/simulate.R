#' @title Simulation wrapper for binomial and normal
#'
#' @description Wrapper function for complete binomial and normal function to
#'   compute power and type I error.
#'
#' @param input list. Input function for all inputs in binomial, normal, and
#'   survival.
#' @param no_of_sim numeric. Number of simulations to run.
#' @param .data NULL. Stores the proportion of control and treatment, please do
#'   not fill it in.
#'
#' @return A list with results of the simulation (power and type I error) and
#'   the input.
#'
#' \describe{
#'   \item{\code{input}}{
#'     A list of input values used in the trial simulation.}
#'   \item{\code{power}}{
#'     data frame. A data frame with the interim look and power at each look.}
#'   \item{\code{type1_error}}{
#'     scalar. The type I error or the proportion of times the trial rejects the null
#'     when the parameters are simulated under the null hypothesis.}
#'   \item{\code{est_final}}{
#'     vector. The final estimate of the difference in posterior estimate of
#'     treatment and posterior estimate of the control group for all the
#'     simulations.}
#'   \item{\code{post_prob_accept_alternative}}{
#'     vector. The final probability of accepting the alternative for the
#'     simulations.}
#'   \item{\code{N_enrolled}}{
#'     vector. The number of patients enrolled in the trial (sum of control
#'     and experimental group for each simulation).}
#'   \item{\code{stop_futility}}{
#'     vector. Did the trial stop for futility during imputation of patient
#'     who had loss to follow up? 1 for yes and 0 for no.}
#'   \item{\code{stop_expected_success}}{
#'     vector. Did the trial stop for early success during imputation of patient
#'     who had loss to follow up? 1 for yes and 0 for no.}
#'
#' }
#'
#' @importFrom stats rbinom glm
#' @importFrom dplyr mutate filter group_by bind_rows select n
#' @importFrom purrr map_dbl
#' @importFrom bayesDP bdpbinomial
#'
#' @export simulate

simulate <- function(input, no_of_sim = 10000, .data = NULL) {
  output_power <- list()
  output_type1 <- list()
  input_t1 <- input

  if (!is.null(input_t1$p_treatment)) {
    if (!is.null(input_t1$p_control)) {
      input_t1$p_treatment <- input_t1$p_control
    } else {
      input_t1$h0 <- 0
    }
    for (i in 1:no_of_sim) {
      output_power[[i]] <- do.call(binomialBACT, input)
      output_type1[[i]] <- do.call(binomialBACT, input_t1)
    }
  } else if (!is.null(input_t1$mu_treatment)) {
    if (!is.null(input_t1$mu_control)) {
      input_t1$mu_treatment <- input_t1$mu_control
    } else {
      input_t1$h0 <- 0
    }
    for (i in 1:no_of_sim) {
      output_power[[i]] <- do.call(normalBACT, input)
      output_type1[[i]] <- do.call(normalBACT, input_t1)
    }
  } else if (!is.null(input_t1$hazard_treatment)) {
    if (!is.null(input_t1$hazard_control)) {
      input_t1$hazard_treatment <- input_t1$hazard_control
    } else {
      if (!is.null(input_t1$h0)) {
        input_t1$h0 <- input_t1$h0 + 0.10
      } else {
        input_t1$h0 <- 0.75
      }
    }
    for (i in 1:no_of_sim) {
      output_power[[i]] <- do.call(survivalBACT, input)
      output_type1[[i]] <- do.call(survivalBACT, input_t1)
    }
  }

  prob_ha <- output_power %>%
    map_dbl(c("post_prob_accept_alternative"))
  N_stop <- output_power %>%
    map_dbl(c("N_enrolled"))
  expect_success <- output_power %>%
    map_dbl(c("stop_expected_success"))
  stop_fail <- output_power %>%
    map_dbl(c("stop_futility"))
  est_final <- output_power %>%
    map_dbl(c("est_final"))

  looks <- unique(sort(c(output_power[[1]]$interim_look,
                         output_power[[1]]$N_max)))
  power <- rep(0, length(looks))

  if (length(looks) > 1) {
    for(m in 1:(length(looks) - 1)) {
      if (m == 1) {
        power[1] <- mean((N_stop == looks[m] & expect_success == 1 &
                            prob_ha > output_power[[1]]$prob_of_accepting_alternative))
      } else {
        power[m] <- mean((N_stop == looks[m] & expect_success == 1 &
                            prob_ha > output_power[[1]]$prob_of_accepting_alternative)) +
          power[m - 1]
      }
    }
    power[length(looks)] <- mean((N_stop == looks[length(looks)] &
                                    prob_ha > output_power[[1]]$prob_of_accepting_alternative)) +
      power[length(looks) - 1]
  } else {
    power[length(looks)] <- mean((N_stop == looks[length(looks)] &
                                    prob_ha > output_power[[1]]$prob_of_accepting_alternative))
  }

  power <- data.frame(interim_looks = looks,
                      power = power)

  prob_ha_t1 <- output_type1 %>%
    map_dbl(c("post_prob_accept_alternative"))
  expect_success_t1 <- output_type1 %>%
    map_dbl(c("stop_expected_success"))

  type1_error <- mean(prob_ha_t1 > output_power[[1]]$prob_of_accepting_alternative)

  return(list(input                         = input,
              power                         = power,
              type1_error                   = type1_error,
              est_final                     = est_final,
              post_prob_accept_alternative  = prob_ha,
              N_enrolled                    = N_stop,
              stop_expect_success           = expect_success,
              stop_futility                 = stop_fail))

}
