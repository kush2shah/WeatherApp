# Task Completion Checklist

When completing a task in this project, follow these steps:

## 1. Code Quality
- [ ] Ensure code follows the project's naming conventions (PascalCase for types, camelCase for variables)
- [ ] Add appropriate access control modifiers (`private` for helper functions)
- [ ] Include standard file header comments on new files
- [ ] Use proper SwiftUI property wrappers (@Environment, @Query, etc.)
- [ ] Wrap state changes in `withAnimation { }` where appropriate

## 2. Testing
- [ ] Write or update tests in `WeatherAppTests/` for new functionality
- [ ] Use Swift Testing framework with `@Test` attribute
- [ ] Use `#expect(...)` for assertions
- [ ] Run tests to ensure they pass: `xcodebuild -scheme WeatherApp test`

## 3. SwiftUI Previews
- [ ] Add `#Preview` macros to new views for development convenience

## 4. Build Verification
- [ ] Ensure project builds without errors: `xcodebuild -scheme WeatherApp build`
- [ ] Check for and resolve any warnings

## 5. Version Control
- [ ] Review changes with `git status` and `git diff`
- [ ] Stage relevant files: `git add <files>`
- [ ] Commit with descriptive message: `git commit -m "description"`

## Notes
- **No automatic linting/formatting**: This project does not currently have SwiftLint or SwiftFormat configured
- **Testing is important**: Always verify functionality works as expected
- **Xcode preferred**: While some commands work from CLI, full development experience requires Xcode
