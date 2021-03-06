% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/binomial.R
\name{data_binomial}
\alias{data_binomial}
\title{Data file for binomial analysis}
\usage{
data_binomial(treatment, outcome, complete, .data = NULL)
}
\arguments{
\item{treatment}{vector. Treatment assignment for patients, 1 for treatment
group and 0 for control group}

\item{outcome}{vector. Binomial outcome of the trial, 1 for response (success
or failure), 0 for no response.}

\item{complete}{vector. Similar length as treatment and outcome variable, 1
for complete outcome, 0 for loss to follow up. If complete is not provided,
the dataset is assumed to be complete.}

\item{.data}{NULL. Stores the binomial data for analysis. Should not be
edited by user.}
}
\value{
A list with treatment, outcome and loss to follow up vector with
  binomial outcome.
}
\description{
Wrapper function for data file in binomial analysis.
}
\examples{
data_binomial(treatment = c(0, 1), outcome = c(1, 1), complete = c(1, 1))

}
