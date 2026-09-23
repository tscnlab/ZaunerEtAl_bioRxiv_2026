#include <TMB.hpp>

template<class Type>
Type logspace_add_ou(Type log_x, Type log_y) {
  Type maximum = CppAD::CondExpGt(log_x, log_y, log_x, log_y);
  return maximum + log(exp(log_x - maximum) + exp(log_y - maximum));
}

template<class Type>
Type beta_binomial_logpmf_ou(Type y, Type n, Type mu, Type phi) {
  Type alpha = mu * phi;
  Type beta = (Type(1) - mu) * phi;
  return lgamma(n + Type(1)) -
    lgamma(y + Type(1)) -
    lgamma(n - y + Type(1)) +
    lgamma(y + alpha) +
    lgamma(n - y + beta) -
    lgamma(n + alpha + beta) +
    lgamma(alpha + beta) -
    lgamma(alpha) -
    lgamma(beta);
}

template<class Type>
Type objective_function<Type>::operator() () {
  DATA_IVECTOR(y);
  DATA_IVECTOR(n);
  DATA_MATRIX(X_mu);
  DATA_MATRIX(X_zero);
  DATA_MATRIX(X_one);
  DATA_MATRIX(X_disp);
  DATA_MATRIX(Z_mu_part);
  DATA_IVECTOR(part_index);
  DATA_IVECTOR(one_active);
  DATA_IVECTOR(ou_new_series);
  DATA_VECTOR(ou_gap_days);

  PARAMETER_VECTOR(beta_mu);
  PARAMETER_VECTOR(beta_zero);
  PARAMETER_VECTOR(beta_one);
  PARAMETER_VECTOR(beta_disp);
  PARAMETER_MATRIX(b_mu_part);
  PARAMETER_VECTOR(log_sd_mu_part);
  PARAMETER_VECTOR(u_ou);
  PARAMETER(log_sd_ou);
  PARAMETER(log_rate_ou);

  int observations = y.size();
  int participant_count = b_mu_part.rows();
  int participant_terms = b_mu_part.cols();
  Type negative_log_likelihood = Type(0);
  Type participant_sd = exp(log_sd_mu_part(0));
  Type ou_sd = exp(log_sd_ou);
  Type ou_rate = exp(log_rate_ou);

  for (int participant = 0; participant < participant_count; participant++) {
    for (int term = 0; term < participant_terms; term++) {
      negative_log_likelihood -= dnorm(
        b_mu_part(participant, term),
        Type(0),
        participant_sd,
        true
      );
    }
  }

  for (int observation = 0; observation < observations; observation++) {
    if (ou_new_series(observation) == 1) {
      negative_log_likelihood -= dnorm(
        u_ou(observation),
        Type(0),
        ou_sd,
        true
      );
    } else {
      Type correlation = exp(-ou_rate * ou_gap_days(observation));
      Type conditional_sd = ou_sd * sqrt(
        Type(1) - correlation * correlation
      );
      negative_log_likelihood -= dnorm(
        u_ou(observation),
        correlation * u_ou(observation - 1),
        conditional_sd,
        true
      );
    }
  }

  vector<Type> eta_mu = X_mu * beta_mu;
  vector<Type> eta_zero = X_zero * beta_zero;
  vector<Type> eta_one = X_one * beta_one;
  vector<Type> eta_disp = X_disp * beta_disp;
  vector<Type> mu(observations);
  vector<Type> phi(observations);
  vector<Type> pi_zero(observations);
  vector<Type> pi_one(observations);
  vector<Type> pi_beta(observations);
  vector<Type> conditional_mean(observations);
  vector<Type> conditional_variance(observations);
  vector<Type> log_likelihood(observations);

  for (int observation = 0; observation < observations; observation++) {
    int participant = part_index(observation);
    for (int term = 0; term < participant_terms; term++) {
      eta_mu(observation) +=
        Z_mu_part(observation, term) * b_mu_part(participant, term);
    }
    eta_mu(observation) += u_ou(observation);

    mu(observation) = invlogit(eta_mu(observation));
    phi(observation) = exp(eta_disp(observation));

    Type log_pi_zero = Type(0);
    Type log_pi_one = Type(0);
    Type log_pi_beta = Type(0);
    if (one_active(observation) == 1) {
      Type log_denominator = logspace_add_ou(
        Type(0),
        logspace_add_ou(eta_zero(observation), eta_one(observation))
      );
      log_pi_zero = eta_zero(observation) - log_denominator;
      log_pi_one = eta_one(observation) - log_denominator;
      log_pi_beta = -log_denominator;
      pi_zero(observation) = exp(log_pi_zero);
      pi_one(observation) = exp(log_pi_one);
      pi_beta(observation) = exp(log_pi_beta);
    } else {
      Type log_denominator = logspace_add_ou(Type(0), eta_zero(observation));
      log_pi_zero = eta_zero(observation) - log_denominator;
      log_pi_beta = -log_denominator;
      pi_zero(observation) = exp(log_pi_zero);
      pi_one(observation) = Type(0);
      pi_beta(observation) = exp(log_pi_beta);
    }

    Type log_beta_binomial = beta_binomial_logpmf_ou(
      Type(y(observation)),
      Type(n(observation)),
      mu(observation),
      phi(observation)
    );
    Type observation_log_likelihood = log_pi_beta + log_beta_binomial;
    if (y(observation) == 0) {
      observation_log_likelihood = logspace_add_ou(
        observation_log_likelihood,
        log_pi_zero
      );
    }
    if (one_active(observation) == 1 && y(observation) == n(observation)) {
      observation_log_likelihood = logspace_add_ou(
        observation_log_likelihood,
        log_pi_one
      );
    }
    log_likelihood(observation) = observation_log_likelihood;
    negative_log_likelihood -= observation_log_likelihood;

    Type beta_binomial_fraction_variance =
      mu(observation) * (Type(1) - mu(observation)) *
      (phi(observation) + Type(n(observation))) /
      (Type(n(observation)) * (phi(observation) + Type(1)));
    conditional_mean(observation) =
      pi_one(observation) + pi_beta(observation) * mu(observation);
    Type second_moment =
      pi_one(observation) +
      pi_beta(observation) *
      (
        mu(observation) * mu(observation) +
        beta_binomial_fraction_variance
      );
    conditional_variance(observation) =
      second_moment -
      conditional_mean(observation) * conditional_mean(observation);
  }

  Type ou_half_life_days = log(Type(2)) / ou_rate;
  REPORT(eta_mu);
  REPORT(eta_zero);
  REPORT(eta_one);
  REPORT(eta_disp);
  REPORT(mu);
  REPORT(phi);
  REPORT(pi_zero);
  REPORT(pi_one);
  REPORT(pi_beta);
  REPORT(conditional_mean);
  REPORT(conditional_variance);
  REPORT(log_likelihood);
  REPORT(participant_sd);
  REPORT(ou_sd);
  REPORT(ou_rate);
  REPORT(ou_half_life_days);
  ADREPORT(participant_sd);
  ADREPORT(ou_sd);
  ADREPORT(ou_rate);
  ADREPORT(ou_half_life_days);

  return negative_log_likelihood;
}
