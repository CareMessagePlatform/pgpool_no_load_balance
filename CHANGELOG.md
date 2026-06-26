# Change Log

All notable changes to this project will be documented in this file.
 
The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).
 
## [Unreleased] - yyyy-mm-dd
 
Here we write upgrading notes for brands. It's a team effort to make them as
straightforward as possible.
 
### Added
- [PROJECTNAME-XXXX](http://tickets.projectname.com/browse/PROJECTNAME-XXXX)
  MINOR Ticket title goes here.
- [PROJECTNAME-YYYY](http://tickets.projectname.com/browse/PROJECTNAME-YYYY)
  PATCH Ticket title goes here.
 
### Changed
 
### Fixed

### Security

## [1.3.0] - 2026-06-26

Configurable, multi-valued backend selection for pgpool and/or PgDog.

### Added
- `PgpoolNoLoadBalance.backends` / `backends=` accepts one or more backends
  (`:pgpool`, `:pgdog`, an array, or a comma-separated string). Defaults to
  `[:pgpool]`, so existing behavior is unchanged.
- When multiple backends are configured, each backend's comment is prepended in
  canonical order (pgpool first), e.g.
  `/*NO LOAD BALANCE*/ /* pgdog_role: primary */`.

### Changed
- Renamed the relation/model/arel API to `no_load_balance`; `pgpool_nlb` remains
  a full alias (method, `execute:` keyword, and unscope symbol).
- `ExplainSubscriber` now strips every known backend comment.

## [1.2.0] - 2025-08-28

Rails 7.2 support

## [1.1.0] - 2020-06-14
 
Executes any SQL statement with comments.
 
### Added
- Added pgpool_nlb option to AR #execute.
 
## [1.0.3] - 2020-05-05
 
for RubyGems release.
 
## [1.0.2] - 2020-05-05
 
### Added
- Adapter check feature. (PostgreSQLAdapterMissing exception is raised if the application is not using the Postgresql adaptor.)
 
## [1.0.1] - 2020-05-05
 
### Added
 
### Changed

- change module name.
 
### Fixed

### Security
 
## [1.0.0] - 2020-05-05
 
First release!
 