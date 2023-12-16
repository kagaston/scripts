# Logs the current date to the error log file.
echo date > logs/error.log

# Adds Homebrew core to the global git configuration as a safe directory.
# This is important for allowing git operations within the Homebrew directory.
ensure_no_root () {
  echo "-> Adding Homebrew core to the trusted config"
  git config --global --add safe.directory /usr/local/Homebrew/Library/Taps/homebrew/homebrew-core
}

# Installs Homebrew if it's not already installed.
# This function checks for the presence of the 'brew' command and installs Homebrew using a script from their official repository if it's absent.
install_brew () {
  echo "-> Checking if Homebrew is installed, installing if not..."
  [[ -f $(which brew) ]] ||  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
}

# Disables Homebrew's analytics feature.
# Homebrew collects anonymous usage analytics by default. This function turns that feature off for privacy.
disable_analytics () {
  echo "-> Disabling brew analytics"
  brew analytics off
}

# Adds necessary taps for cask versions and default casks in Homebrew.
# Taps are external sources for Homebrew formulae and casks. This function adds the 'cask-versions' for managing different versions of cask installs.
tap_default_casks () {
  echo "-> Adding basic configurations and the ability to tap casks by version"
  brew tap homebrew/cask-versions
  brew tap homebrew/cask
}

# Updates Homebrew and all formulae to the latest.
# This function updates the list of available packages and their versions, without upgrading the installed packages.
update_brew () {
  echo "-> Updating Homebrew"
  brew update --auto-update
}

# Cleans up unnecessary files and old versions of installed formulae.
# This housekeeping function removes outdated and redundant files from the Homebrew installation, freeing up disk space.
cleanup_brew () {
  echo "-> Cleaning up Homebrew configs"
  brew cleanup --prune-prefix
}

# Installs a given Homebrew package.
# This function takes a package name as an argument and uses Homebrew to install it.
install(){
  echo "  -> brew install $1"
  brew install $1
}

# Upgrades a given Homebrew package.
# This function takes a package name as an argument and upgrades it to the latest version using Homebrew.
update(){
  echo "  -> brew upgrade $1"
  brew upgrade $1
}

# Unlinks and then links a given Homebrew package.
# Useful for fixing issues related to linking or for switching between versions of the same package.
link(){
  echo "  -> brew unlink $1"
  brew unlink $1
  echo "  -> brew link $1"
  brew link $1
}

# Installs a predefined list of Homebrew packages and performs update and linking operations.
# The list includes essential development tools and languages like Docker, Ruby, and Python.
install_brew_modules(){
  brew_modules=( docker ruby perl python lampepfl/brew/dotty sbt apache-spark git curl)
  for module in "${brew_modules[@]}"
    do
      echo "=> Installing $module"
      install $module
      update $module
      link $module
  done

  brew install temurin11 --cask
  brew upgrade temurin11 --cask
  link temurin11
}

# Removes empty lines from the .zshrc file.
# This cleanup helps in maintaining a clean and readable shell configuration file.
sed -i -r '/^[[:blank:]]*$/ d' ~/.zshrc

# Configures Ruby environment variables in the .zshrc file.
# This function sets the PATH, LDFLAGS, and CPPFLAGS environment variables for Ruby, ensuring that the Ruby installation and its libraries are correctly located.
configure_ruby(){
  # remove old path entries
  sed -i -r 's/# Ruby Path variables.*//' ~/.zshrc
  sed -i -r 's/.*opt\/ruby.*//' ~/.zshrc

  # add new path entries
  echo '# Ruby Path variables' >> ~/.zshrc
  echo 'export PATH="/usr/local/opt/ruby/bin:$PATH"' >> ~/.zshrc
  echo 'export LDFLAGS="-L/usr/local/opt/ruby/lib"' >> ~/.zshrc
  echo 'export CPPFLAGS="-I/usr/local/opt/ruby/include"' >> ~/.zshrc
}

# Configures Python environment and aliases in the .zshrc file.
# Installs and upgrades pip, sets up Python-related aliases for ease of use.
configure_python(){
  # Configure Python
  # Install requirements
  python -m pip install --upgrade pip

  # Install pip tools
  pip install pip-tools

  # clear old alias entries
  sed -i -r 's/# Python Aliases//' ~/.zshrc
  sed -i -r 's/alias python.*//' ~/.zshrc
  sed -i -r 's/alias pip.*//' ~/.zshrc

  # Add new alias in file path
  echo '# Python Aliases' >> ~/.zshrc
  echo 'alias python="python3"' >> ~/.zshrc
  echo 'alias pip="pip3"' >> ~/.zshrc
}

# Configures Apache Spark environment variables in the .zshrc file.
# Sets the SPARK_HOME variable and adjusts the PATH to include Spark's bin directory, ensuring that Spark's command-line tools are accessible.
configure_spark(){
  # Clear old path entries
  sed -i -r 's/# Spark Path variables//' ~/.zshrc
  sed -i -r 's/export SPARK_.*//' ~/.zshrc
  sed -i -r 's/export PATH="$SPARK_HOME.*//' ~/.zshrc

  # Add new path entries
  echo '# Spark Path variables' >> ~/.zshrc
  echo 'export SPARK_HOME="/usr/local/Cellar/apache-spark/3.3.0/libexec"' >> ~/.zshrc
  echo 'export PATH="$SPARK_HOME/bin/:$PATH"' >> ~/.zshrc
  # Needs to be executable
  chmod +x /usr/local/Cellar/apache-spark/3.3.0/libexec/bin/*
}

# Configures PySpark environment variables in the .zshrc file.
# Sets variables to integrate PySpark with Jupyter, specifying that Jupyter should be used as the driver for PySpark sessions.
configure_pyspark(){
  sed -i -r 's/# PYSPARK Path variables.*//' ~/.zshrc
  sed -i -r 's/export PYSPARK.*//' ~/.zshrc

  echo '# PYSPARK Path variables' >> ~/.zshrc
  echo 'export PYSPARK_DRIVER_PYTHON=jupyter' >> ~/.zshrc
  echo 'export PYSPARK_DRIVER_PYTHON_OPTS='notebook'' >> ~/.zshrc
}

# Reloads the shell configuration to apply changes immediately.
reload_source(){
  source  ~/.zshrc
}

# The main function that orchestrates the execution of setup and configuration functions.
# It checks if the script is running on macOS and proceeds with the setup if true.
main () {
  ensure_no_root
  install_brew
  disable_analytics
  tap_default_casks
  update_brew
  install_brew_modules
  cleanup_brew
  configure_ruby
  configure_python
  configure_spark
  # configure_pyspark (uncomment this if you want to configure PySpark)
  reload_source
}

# Executes the main entry point if running on macOS (Darwin).
[[ $(uname) == [Dd]arwin* ]] && main || echo "Skipping this does not look to be OSX variant..."
