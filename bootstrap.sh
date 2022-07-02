echo date > logs/error.log

ensure_no_root () {
  echo "-> Adding Homebrew core to the trusted config"
  git config --global --add safe.directory /usr/local/Homebrew/Library/Taps/homebrew/homebrew-core
}

install_brew () {
  echo "-> Checking if Homebrew is installed, installing if not..."
  [[ -f $(which brew) ]] ||  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
}

disable_analytics () {
  echo "-> Disabling brew analytics"
  brew analytics off
}

tap_default_casks () {
  echo "-> Adding basic configurations and the ability to tap casks by version"
  brew tap homebrew/cask-versions
  brew tap homebrew/cask
}

update_brew () {
  echo "-> Updating Homebrew"
  brew update --auto-update
}

cleanup_brew () {
  echo "-> Cleaning up Homebrew configs"
  brew cleanup --prune-prefix
}

install(){
  echo "  -> brew install $1"
  brew install $1
}

update(){
  echo "  -> brew upgrade $1"
  brew upgrade $1
}

link(){
  echo "  -> brew unlink $1"
  brew unlink $1
  echo "  -> brew link $1"
  brew link $1
}

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

sed -i -r '/^[[:blank:]]*$/ d' ~/.zshrc

configure_ruby(){
  # remove old path entries
  sed -i -r 's/# Ruby Path variables.*//' ~/.zshrc
  sed -i -r 's/.*opt\/ruby.*//' ~/.zshrc

  # add nw path entries
  echo '# Ruby Path variables' >> ~/.zshrc
  echo 'export PATH="/usr/local/opt/ruby/bin:$PATH"' >> ~/.zshrc
  echo 'export LDFLAGS="-L/usr/local/opt/ruby/lib"' >> ~/.zshrc
  echo 'export CPPFLAGS="-I/usr/local/opt/ruby/include"' >> ~/.zshrc

}

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

configure_spark(){
  # Clear old path entries
  sed -i -r 's/# Spark Path variables//' ~/.zshrc
  sed -i -r 's/export SPARK_.*//' ~/.zshrc
  sed -i -r 's/export PATH="$SPARK_HOME.*//' ~/.zshrc

  #SPARK_VERSION=$(brew info apache-spark | grep -Eo "/usr/local/\S+")

  # Add new path entries
  echo '# Spark Path variables' >> ~/.zshrc
  echo 'export SPARK_HOME="/usr/local/Cellar/apache-spark/3.3.0/libexec"' >> ~/.zshrc
  echo 'export PATH="$SPARK_HOME/bin/:$PATH"' >> ~/.zshrc
  # Needs to be executable
  chmod +x /usr/local/Cellar/apache-spark/3.3.0/libexec/bin/*
}

configure_pyspark(){

  sed -i -r 's/# PYSPARK Path variables.*//' ~/.zshrc
  sed -i -r 's/export PYSPARK.*//' ~/.zshrc

  echo '# PYSPARK Path variables' >> ~/.zshrc
  echo 'export PYSPARK_DRIVER_PYTHON=jupyter' >> ~/.zshrc
  echo 'export PYSPARK_DRIVER_PYTHON_OPTS='notebook'' >> ~/.zshrc

}

reload_source(){
  source  ~/.zshrc
}

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
#  configure_pyspark
  reload_source
}


# Executes the main entry point if OSX
[[ $(uname) == [Dd]arwin* ]] && main || echo "Skipping this does not look to be OSX variant..."
