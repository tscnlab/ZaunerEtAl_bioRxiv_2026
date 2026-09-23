#include <TMB.hpp>

template<class Type>
Type logspace_add_pair(Type log_x, Type log_y) {
  Type maximum = CppAD::CondExpGt(log_x, log_y, log_x, log_y);
  return maximum + log(exp(log_x - maximum) + exp(log_y - maximum));
}

template<class Type>
Type beta_binomial_logpmf(Type y, Type n, Type mu, Type phi) {
  Type alpha = mu * phi;
  Type beta = (Type(1) - mu) * phi;
  return lgamma(n + Type(1)) - lgamma(y + Type(1)) -
    lgamma(n - y + Type(1)) + lgamma(y + alpha) +
    lgamma(n - y + beta) - lgamma(n + alpha + beta) +
    lgamma(alpha + beta) - lgamma(alpha) - lgamma(beta);
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
  DATA_IVECTOR(day_index);
  DATA_IVECTOR(one_active);
  DATA_INTEGER(use_zero_component);
  DATA_INTEGER(use_mu_part_re);
  DATA_INTEGER(use_day_re);
  DATA_INTEGER(use_zero_re);
  DATA_INTEGER(use_one_re);

  PARAMETER_VECTOR(beta_mu);
  PARAMETER_VECTOR(beta_zero);
  PARAMETER_VECTOR(beta_one);
  PARAMETER_VECTOR(beta_disp);
  PARAMETER_MATRIX(b_mu_part);
  PARAMETER_VECTOR(b_day);
  PARAMETER_VECTOR(b_zero_part);
  PARAMETER_VECTOR(b_one_part);
  PARAMETER_VECTOR(log_sd_mu_part);
  PARAMETER(log_sd_day);
  PARAMETER(log_sd_zero);
  PARAMETER(log_sd_one);

  int observations = y.size();
  int participant_count = b_mu_part.rows();
  int participant_terms = b_mu_part.cols();
  Type nll = Type(0);

  if (use_mu_part_re == 1) {
    for (int participant = 0; participant < participant_count; participant++) {
      for (int term = 0; term < participant_terms; term++) {
        nll -= dnorm(
          b_mu_part(participant, term),
          Type(0),
          exp(log_sd_mu_part(term)),
          true
        );
      }
    }
  }
  if (use_day_re == 1) {
    for (int day = 0; day < b_day.size(); day++) {
      nll -= dnorm(b_day(day), Type(0), exp(log_sd_day), true);
    }
  }
  if (use_zero_re == 1) {
    for (int participant = 0; participant < b_zero_part.size(); participant++) {
      nll -= dnorm(b_zero_part(participant), Type(0), exp(log_sd_zero), true);
    }
  }
  if (use_one_re == 1) {
    for (int participant = 0; participant < b_one_part.size(); participant++) {
      nll -= dnorm(b_one_part(participant), Type(0), exp(log_sd_one), true);
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
    if (use_mu_part_re == 1) {
      for (int term = 0; term < participant_terms; term++) {
        eta_mu(observation) += Z_mu_part(observation, term) *
          b_mu_part(participant, term);
      }
    }
    if (use_day_re == 1) {
      eta_mu(observation) += b_day(day_index(observation));
    }
    if (use_zero_re == 1) {
      eta_zero(observation) += b_zero_part(participant);
    }
    if (use_one_re == 1 && one_active(observation) == 1) {
      eta_one(observation) += b_one_part(participant);
    }

    mu(observation) = invlogit(eta_mu(observation));
    phi(observation) = exp(eta_disp(observation));
    Type log_denominator = logspace_add_pair(
      Type(0),
      logspace_add_pair(eta_zero(observation), eta_one(observation))
    );
    Type log_pi_zero = eta_zero(observation) - log_denominator;
    Type log_pi_one = eta_one(observation) - log_denominator;
    Type log_pi_beta = -log_denominator;
    pi_zero(observation) = exp(log_pi_zero);
    pi_one(observation) = exp(log_pi_one);
    pi_beta(observation) = exp(log_pi_beta);

    Type log_beta = beta_binomial_logpmf(
      Type(y(observation)),
      Type(n(observation)),
      mu(observation),
      phi(observation)
    );
    Type observation_log_likelihood = log_pi_beta + log_beta;
    if (y(observation) == 0) {
      observation_log_likelihood = logspace_add_pair(
        observation_log_likelihood,
        log_pi_zero
      );
    }
    if (y(observation) == n(observation)) {
      observation_log_likelihood = logspace_add_pair(
        observation_log_likelihood,
        log_pi_one
      );
    }
    log_likelihood(observation) = observation_log_likelihood;
    nll -= observation_log_likelihood;

    Type beta_variance = mu(observation) * (Type(1) - mu(observation)) *
      (phi(observation) + Type(n(observation))) /
      (Type(n(observation)) * (phi(observation) + Type(1)));
    conditional_mean(observation) = pi_one(observation) +
      pi_beta(observation) * mu(observation);
    Type second_moment = pi_one(observation) + pi_beta(observation) *
      (mu(observation) * mu(observation) + beta_variance);
    conditional_variance(observation) = second_moment -
      conditional_mean(observation) * conditional_mean(observation);
  }

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

  SIMULATE {
    vector<Type> y_simulated(observations);
    for (int observation = 0; observation < observations; observation++) {
      Type component_draw = runif(Type(0), Type(1));
      if (component_draw < pi_zero(observation)) {
        y_simulated(observation) = Type(0);
      } else if (component_draw < pi_zero(observation) + pi_one(observation)) {
        y_simulated(observation) = Type(n(observation));
      } else {
        Type probability = rbeta(
          mu(observation) * phi(observation),
          (Type(1) - mu(observation)) * phi(observation)
        );
        y_simulated(observation) = rbinom(Type(n(observation)), probability);
      }
    }
    REPORT(y_simulated);
  }

  return nll;
}
