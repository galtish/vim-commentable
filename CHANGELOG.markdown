Changelog
=========

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

[unreleased]
------------

[0.3.2] - 2018-09-25
--------------------

### Fixed
- Now reformats blocks taking into account the indent of the start of the
  block, rather than where the cursor happens to be. Correctly uses the
  top-left corner as the anchor point.

### Other
- Suites now listed in tests/lua-modules/suites.lua rather than
  tests/suites.cfg. Doesn't affect runtime.

[0.3.1] - 2018-06-11
--------------------

### Fixed
- Minor performance improvements - don't use so many exceptions
- Add docs.

[0.3.0] - 2017-09-24
--------------------

### Added
- CommentableBlock/SubStyle now accepts a 'regex' part of the matcher to
  handle different comments within a single file.

### Changed
- CommentableParagraphIntro now auto-inserts leading whitespace.

### Fixed
- CommentableParagraphIntro now correctly matches sub-lists.
- Now handles unicode text in comments
- Now correctly handles blank lines which are too long

### Other
- ./run-most-recent-test script for faster testing in development.

[0.2.0] - 2017-03-25
--------------------

### Added
- CommentableSetDefaultBindings adds some standard maps.

### Changed
- CommentableCreate has join functionality.

### Removed
- No submodule dependencies.

### Other
- Better commenting througout.
- Pretty colours for test output.

[0.1.0] - 2016-12-10
--------------------

### Added
- Initial project structure, tests and functionality.

[unreleased]: https://www.github.com/FalacerSelene/vim-commentable
[0.3.2]: https://www.github.com/FalacerSelene/vim-commentable/tree/0.3.2
[0.3.1]: https://www.github.com/FalacerSelene/vim-commentable/tree/0.3.1
[0.3.0]: https://www.github.com/FalacerSelene/vim-commentable/tree/0.3.0
[0.2.0]: https://www.github.com/FalacerSelene/vim-commentable/tree/0.2.0
[0.1.0]: https://www.github.com/FalacerSelene/vim-commentable/tree/0.1.0
