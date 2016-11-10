#' @title Produce a message for the output of a checkFunction
#' @description Internal function for producing output messages in \code{\link{checkFunction}}
#' type functions called by \code{\link{clean}}.
#'
#' @param problemStatus A list consisting of two entries: $problem - TRUE/FALSE indicating
#' whether a problem was found by the \code{checkFunction}, $problemValues - a vector of values
#' from the variable that were deemed problematic. See details below.
#'
#' @param message Optional, but recommended. A message describing what problem the
#' problem values are related to. If \code{NULL} a standard message is added using the name
#' of the function that called \code{messageGenerator}.
#'
#' @param nMax Maximum number of problem values to be printed in the message. If the total
#' number of problem values exceeds nMax, the number of remaining (non-printed) problem
#' values are added to the message. Defaults to \code{Inf} in which case all problem
#' values are printed.
#'
#' @details This function is a tool for building \code{\link{checkFunction}}s for the
#' cleanR \code{\link{clean}} function. \code{checkFunction}s will often identify a number
#' of values in a variable that are somehow problematic. \code{messageGenerator} takes
#' these values, pastes them together with a problem description and makes sure that the
#' formatting is appropriate for being rendered in a rmarkdown document. We recommend writing
#' short at precise problem descriptions (see examples), but if no message is supplied,
#' the following message is generated:
#' "[function name] found the following problem values: [problem values]".
#' Note that this option only works correctly when the checkFunction is called directly and e.g.
#' not dispatched through a generic function.
#'
#' @return A character string.
#'
#' @seealso \code{\link{check}} \code{\link{checkFunction}}
#'
#' @examples
#'
#' #Varibales with/without underscores
#'  noUSVar <- c(1:10)
#'  USVar <- c("_a", "n_b", "b_", "_", 1:10)
#'
#' #Define a checkFunction using messageGenerator with a manual
#' #problem description:
#' identifyUnderscores <- function(v, nMax = Inf) {
#'   v <- as.character(v)
#'   underscorePlaces <- regexpr("_", v) > 0
#'   problemValues <- unique(v[underscorePlaces])
#'   problem <- any(underscorePlaces)
#'   message <- messageGenerator(list(problemValues = problemValues, problem = problem),
#'                               "The following values contain underscores:",
#'                               nMax = nMax)
#'   list(problem = problem, message = message)
#'  }
#'
#'  identifyUnderscores(noUSVar) #no problem
#'  identifyUnderscores(USVar) #problems
#'
#' #Define same function, but without a manual problem description in
#' #the messageGenerator-call:
#'  identifyUnderscores2 <- function(v, nMax = Inf) {
#'   v <- as.character(v)
#'   underscorePlaces <- regexpr("_", v) > 0
#'   problemValues <- unique(v[underscorePlaces])
#'   problem <- any(underscorePlaces)
#'   message <- messageGenerator(list(problemValues = problemValues,
#'                                    problem = problem), nMax = nMax)
#'   list(problem = problem, message = message)
#'  }
#'
#'  identifyUnderscores2(noUSVar) #no problem
#'  identifyUnderscores2(USVar) #problems
#'
#' #Only print the first two problemvalues in the message:
#'  identifyUnderscores2(USVar, nMax = 2)
#'
#' @export
messageGenerator <- function(problemStatus, message = NULL, nMax = Inf) {

  #what functions made the call the message generator?
  callF <- sys.status()$sys.calls
  callF <- sapply(callF, function(x) as.character(x)[1])

  #callF <- as.character(callF[[length(callF) - 2]])[1]

  #standard functions do not need to specify a message when called

  standardCall <- intersect(callF, c("identifyMissing", "identifyWhitespace", "identifyOutliers",
                                     "identifyLoners", "identifyCaseIssues", "identifyOutliersTBStyle"))

  if (length(standardCall==1)) {
    messages <- list(identifyMissing =
                       "The following suspected missing value codes enter as regular values:",
                     identifyWhitespace =
                       "The following values appear with prefixed or suffixed white space:",
                     identifyOutliers =
                       "Note that the following possible outlier values were detected:",
                     identifyLoners =
                       "Note that the following levels have at most five observations:",
                     identifyCaseIssues =
                       "Note that there might be case problems with the following levels:",
                     identifyOutliersTBStyle = 
                       "Note that the following possible outlier values were detected:")
    check <- standardCall
  } else {
    callF <- callF[length(callF) - 2]
    if (is.null(message)) {
      message <- paste(callF, "found the following problem values:")
    }
    messages <- list(onlyMessage = message)
    check <- "onlyMessage"
  }

  ifelse(problemStatus$problem,
         paste(messages[[check]], printProblemValues(problemStatus$problemValues, nMax)),
         "")
}



#############################Not exported below##################################################

#Formats problems values, i.e. escapes characters appropriately for rmarkdown
#and adds quotes such that prefixed and suffixed blankspaces are visible.
#only called when there is at least one problemValue
#NOTE: 3 slashes escapes the espaced string [\"] such that it is printed correctly
#(and not intepreted) in markdown.
printProblemValues <- function(problemValues, nMax = Inf) {
  problemValues <- gsub("\\", "\\\\", problemValues, fixed = TRUE)
  problemValues <- sort(problemValues)
  nVals <- length(problemValues)
  extraStr <- ""
  if (nMax < nVals) {
    problemValues <- problemValues[1:nMax]
    extraStr <- paste("(", nVals-nMax, " additional values omitted)", sep="")
  }
  paste(paste(paste("\\\"", sort(problemValues), "\\\"", sep=""),
        collapse=", "), extraStr)
}