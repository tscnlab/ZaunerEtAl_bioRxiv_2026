#include <TMB.hpp>

template<class Type>
Type logspace_add_ou_estimand(Type log_x, Type log_y) {
  Type maximum = CppAD::CondExpGt(log_x, log_y, log_x, log_y);
  return maximum + log(exp(log_x - maximum) + exp(log_y - maximum));
}

template<class Type>
Type objective_function<Type>::operator() () {
  DATA_MATRIX(X_mu_cell);
  DATA_MATRIX(X_zero_cell);
  DATA_MATRIX(X_one_cell);
  DATA_MATRIX(X_disp_cell);
  DATA_IVECTOR(one_active_cell);
  DATA_VECTOR(gh_nodes);
  DATA_VECTOR(gh_weights);

  PARAMETER_VECTOR(beta_mu);
  PARAMETER_VECTOR(beta_zero);
  PARAMETER_VECTOR(beta_one);
  PARAMETER_VECTOR(beta_disp);
  PARAMETER_VECTOR(log_sd_mu_part);
  PARAMETER(log_sd_ou);
  PARAMETER(log_rate_ou);

  int cells = X_mu_cell.rows();
  int nodes = gh_nodes.size();
  Type participant_variance = exp(Type(2) * log_sd_mu_part(0));
  Type ou_variance = exp(Type(2) * log_sd_ou);
  Type marginal_sd = sqrt(participant_variance + ou_variance);
  vector<Type> eta_mu = X_mu_cell * beta_mu;
  vector<Type> eta_zero = X_zero_cell * beta_zero;
  vector<Type> eta_one = X_one_cell * beta_one;
  vector<Type> eta_disp = X_disp_cell * beta_disp;

  vector<Type> cell_mean(cells);
  vector<Type> cell_pi_zero(cells);
  vector<Type> cell_pi_one(cells);
  vector<Type> cell_pi_beta(cells);
  vector<Type> cell_phi(cells);

  for (int cell = 0; cell < cells; cell++) {
    Type log_denominator;
    if (one_active_cell(cell) == 1) {
      log_denominator = logspace_add_ou_estimand(
        Type(0),
        logspace_add_ou_estimand(eta_zero(cell), eta_one(cell))
      );
      cell_pi_zero(cell) = exp(eta_zero(cell) - log_denominator);
      cell_pi_one(cell) = exp(eta_one(cell) - log_denominator);
      cell_pi_beta(cell) = exp(-log_denominator);
    } else {
      log_denominator = logspace_add_ou_estimand(Type(0), eta_zero(cell));
      cell_pi_zero(cell) = exp(eta_zero(cell) - log_denominator);
      cell_pi_one(cell) = Type(0);
      cell_pi_beta(cell) = exp(-log_denominator);
    }
    cell_phi(cell) = exp(eta_disp(cell));
    cell_mean(cell) = Type(0);
    for (int node = 0; node < nodes; node++) {
      Type mu = invlogit(eta_mu(cell) + marginal_sd * gh_nodes(node));
      cell_mean(cell) += gh_weights(node) * (
        cell_pi_one(cell) + cell_pi_beta(cell) * mu
      );
    }
  }

  Type ou_rate = exp(log_rate_ou);
  Type ou_half_life_days = log(Type(2)) / ou_rate;
  REPORT(cell_mean);
  REPORT(cell_pi_zero);
  REPORT(cell_pi_one);
  REPORT(cell_pi_beta);
  REPORT(cell_phi);
  REPORT(marginal_sd);
  REPORT(ou_half_life_days);
  ADREPORT(cell_mean);
  ADREPORT(cell_pi_zero);
  ADREPORT(cell_pi_one);
  ADREPORT(cell_pi_beta);
  ADREPORT(cell_phi);

  return Type(0);
}
