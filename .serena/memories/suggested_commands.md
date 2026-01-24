# Suggested Commands

## Build and Run
**Note**: This project requires Xcode for building and running. Command line tools alone are insufficient.

### Building
```bash
xcodebuild -scheme WeatherApp -configuration Debug build
```

### Testing
```bash
# Run all tests
xcodebuild -scheme WeatherApp test

# Run specific test target
xcodebuild -scheme WeatherApp -only-testing:WeatherAppTests test
xcodebuild -scheme WeatherApp -only-testing:WeatherAppUITests test
```

### Cleaning
```bash
xcodebuild -scheme WeatherApp clean
```

## Git Commands (macOS/Darwin)
```bash
git status
git add <files>
git commit -m "message"
git push
git pull
```

## File Operations (macOS/Darwin)
```bash
# List files
ls -la

# Find files
find . -name "*.swift"

# Search in files
grep -r "pattern" --include="*.swift" .

# Navigate
cd <directory>
pwd
```

## Swift Commands
```bash
# Check Swift version
swift --version

# Build with Swift Package Manager (if applicable)
swift build

# Run tests with Swift Package Manager (if applicable)
swift test
```

## Xcode Specific
- Open project: `open WeatherApp.xcodeproj`
- Run in Xcode GUI for best development experience
- Use Xcode's built-in testing and debugging tools
