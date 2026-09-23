#include <TMB.hpp>

template<class Type>
Type logspace_add_estimand(Type log_x, Type log_y) {
  Type maximum = CppAD::CondExpGt(log_x, log_y, log_x, log_y);
  return maximum + log(exp(log_x - maximum) + exp(log_y - maximum));
}

template<class Type>
Type beta_binomial_logpmf_estimand(Type y, Type n, Type mu, Type phi) {
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
  DATA_MATRIX(X_mu_cell);
  DATA_MATRIX(X_zero_cell);
  DATA_MATRIX(X_one_cell);
  DATA_MATRIX(X_disp_cell);
  DATA_IVECTOR(one_active_cell);
  DATA_IVECTOR(support_cell_index);
  DATA_IVECTOR(support_denominator);
  DATA_VECTOR(support_weight);
  DATA_VECTOR(gh_nodes);
  DATA_VECTOR(gh_weights);

  PARAMETER_VECTOR(beta_mu);
  PARAMETER_VECTOR(beta_zero);
  PARAMETER_VECTOR(beta_one);
  PARAMETER_VECTOR(beta_disp);
  PARAMETER_VECTOR(log_sd_mu_part);

  int cells = X_mu_cell.rows();
  int support_rows = support_cell_index.size();
  int nodes = gh_nodes.size();
  Type participant_sd = exp(log_sd_mu_part(0));

  vector<Type> eta_mu = X_mu_cell * beta_mu;
  vector<Type> eta_zero = X_zero_cell * beta_zero;
  vector<Type> eta_one = X_one_cell * beta_one;
  vector<Type> eta_disp = X_disp_cell * beta_disp;

  vector<Type> cell_mean(cells);
  vector<Type> cell_all_zero(cells);
  vector<Type> cell_all_one(cells);
  vector<Type> cell_mixed(cells);
  vector<Type> cell_pi_zero(cells);
  vector<Type> cell_pi_one(cells);
  vector<Type> cell_pi_beta(cells);
  vector<Type> cell_phi(cells);

  for (int cell = 0; cell < cells; cell++) {
    Type log_denominator;
    if (one_active_cell(cell) == 1) {
      log_denominator = logspace_add_estimand(
        Type(0),
        logspace_add_estimand(eta_zero(cell), eta_one(cell))
      );
      cell_pi_zero(cell) = exp(eta_zero(cell) - log_denominator);
      cell_pi_one(cell) = exp(eta_one(cell) - log_denominator);
      cell_pi_beta(cell) = exp(-log_denominator);
    } else {
      log_denominator = logspace_add_estimand(Type(0), eta_zero(cell));
      cell_pi_zero(cell) = exp(eta_zero(cell) - log_denominator);
      cell_pi_one(cell) = Type(0);
      cell_pi_beta(cell) = exp(-log_denominator);
    }

    cell_phi(cell) = exp(eta_disp(cell));
    cell_mean(cell) = Type(0);
    for (int node = 0; node < nodes; node++) {
      Type mu = invlogit(
        eta_mu(cell) + participant_sd * gh_nodes(node)
      );
      cell_mean(cell) += gh_weights(node) * (
        cell_pi_one(cell) + cell_pi_beta(cell) * mu
      );
    }
    cell_all_zero(cell) = Type(0);
    cell_all_one(cell) = Type(0);
  }

  for (int support = 0; support < support_rows; support++) {
    int cell = support_cell_index(support);
    Type denominator = Type(support_denominator(support));
    Type probability_zero = Type(0);
    Type probability_one = Type(0);
    for (int node = 0; node < nodes; node++) {
      Type mu = invlogit(
        eta_mu(cell) + participant_sd * gh_nodes(node)
      );
      Type beta_zero = exp(beta_binomial_logpmf_estimand(
        Type(0),
        denominator,
        mu,
        cell_phi(cell)
      ));
      Type beta_one = exp(beta_binomial_logpmf_estimand(
        denominator,
        denominator,
        mu,
        cell_phi(cell)
      ));
      probability_zero += gh_weights(node) * (
        cell_pi_zero(cell) + cell_pi_beta(cell) * beta_zero
      );
      probability_one += gh_weights(node) * (
        cell_pi_one(cell) + cell_pi_beta(cell) * beta_one
      );
    }
    cell_all_zero(cell) += support_weight(support) * probability_zero;
    cell_all_one(cell) += support_weight(support) * probability_one;
  }

  for (int cell = 0; cell < cells; cell++) {
    cell_mixed(cell) =
      Type(1) - cell_all_zero(cell) - cell_all_one(cell);
  }

  REPORT(cell_mean);
  REPORT(cell_all_zero);
  REPORT(cell_all_one);
  REPORT(cell_mixed);
  REPORT(cell_pi_zero);
  REPORT(cell_pi_one);
  REPORT(cell_pi_beta);
  REPORT(cell_phi);

  ADREPORT(cell_mean);
  ADREPORT(cell_all_zero);
  ADREPORT(cell_all_one);
  ADREPORT(cell_mixed);
  ADREPORT(cell_pi_zero);
  ADREPORT(cell_pi_one);
  ADREPORT(cell_pi_beta);
  ADREPORT(cell_phi);

  return Type(0);
}
