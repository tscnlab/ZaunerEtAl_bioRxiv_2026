#include <TMB.hpp>

template<class Type>
Type logspace_add_sensitivity(Type log_x, Type log_y) {
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
  DATA_INTEGER(use_zero_component);
  DATA_VECTOR(gh_nodes);
  DATA_VECTOR(gh_weights);

  PARAMETER_VECTOR(beta_mu);
  PARAMETER_VECTOR(beta_zero);
  PARAMETER_VECTOR(beta_one);
  PARAMETER_VECTOR(beta_disp);
  PARAMETER_VECTOR(log_sd_mu_part);

  int cells = X_mu_cell.rows();
  int nodes = gh_nodes.size();
  Type participant_sd = exp(log_sd_mu_part(0));
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
    if (use_zero_component == 1 && one_active_cell(cell) == 1) {
      log_denominator = logspace_add_sensitivity(
        Type(0),
        logspace_add_sensitivity(eta_zero(cell), eta_one(cell))
      );
      cell_pi_zero(cell) = exp(eta_zero(cell) - log_denominator);
      cell_pi_one(cell) = exp(eta_one(cell) - log_denominator);
      cell_pi_beta(cell) = exp(-log_denominator);
    } else if (use_zero_component == 1) {
      log_denominator = logspace_add_sensitivity(Type(0), eta_zero(cell));
      cell_pi_zero(cell) = exp(eta_zero(cell) - log_denominator);
      cell_pi_one(cell) = Type(0);
      cell_pi_beta(cell) = exp(-log_denominator);
    } else if (one_active_cell(cell) == 1) {
      log_denominator = logspace_add_sensitivity(Type(0), eta_one(cell));
      cell_pi_zero(cell) = Type(0);
      cell_pi_one(cell) = exp(eta_one(cell) - log_denominator);
      cell_pi_beta(cell) = exp(-log_denominator);
    } else {
      cell_pi_zero(cell) = Type(0);
      cell_pi_one(cell) = Type(0);
      cell_pi_beta(cell) = Type(1);
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
  }

  REPORT(cell_mean);
  REPORT(cell_pi_zero);
  REPORT(cell_pi_one);
  REPORT(cell_pi_beta);
  REPORT(cell_phi);

  ADREPORT(cell_mean);
  ADREPORT(cell_pi_zero);
  ADREPORT(cell_pi_one);
  ADREPORT(cell_pi_beta);
  ADREPORT(cell_phi);

  return Type(0);
}
