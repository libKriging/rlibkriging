#!/usr/bin/env Rscript

packages = commandArgs(trailingOnly=TRUE)

if (.Platform$OS.type=="windows")
    options(pkgType = "win.binary") # Prefer windows binary if available (even if not latest version)

# On macOS, try to use binary packages when available
if (Sys.info()["sysname"] == "Darwin") {
    options(pkgType = "both") # Try binary first, then source
}

# Retry wrapper: package repositories (and pak/pkgdepends subprocesses) can fail
# transiently in CI; retry a few times before giving up.
max_attempts <- as.integer(Sys.getenv("PKG_INSTALL_RETRIES", "3"))
retry_delay  <- as.integer(Sys.getenv("PKG_INSTALL_RETRY_DELAY", "15"))

install_with_retry <- function(lib) {
    for (attempt in seq_len(max_attempts)) {
        cat(sprintf("Installing package: %s (attempt %d/%d)\n", lib, attempt, max_attempts))
        try(install.packages(lib, repos = 'https://cloud.r-project.org'), silent = FALSE)
        if (requireNamespace(lib, quietly = TRUE)) return(TRUE)
        if (attempt < max_attempts) {
            cat(sprintf("  ...install of %s failed, retrying in %ds\n", lib, retry_delay))
            Sys.sleep(retry_delay)
        }
    }
    FALSE
}

for (lib in packages) {
    if (!install_with_retry(lib) || !library(lib, character.only=TRUE, logical.return=TRUE)) {
        cat(paste0("\n#########################\nCannot install ", lib, "\n"))
        cat(paste0("System info: ", Sys.info()["sysname"], " ", Sys.info()["release"], "\n"))
        cat(paste0("R version: ", R.version.string, "\n"))
        cat("#########################\n\n")
        quit(status=1, save='no')
    } else {
        cat(paste0("Successfully installed and loaded: ", lib, " (version ", packageVersion(lib), ")\n\n"))
    }
}
