**Windows**

> Step 1. Install git via
> [`http://msysgit.github.com/`](http://msysgit.github.com/)
> (Download version 1.8.4, install default options, select 'Run Git from the Windows Command Prompt')
> Step 2. Install python 2.7.X via
> [`http://www.python.org/getit/`](http://www.python.org/getit/)
> (Afterwards, open a command prompt and type `set PATH=%PATH%;C:\Python27`)
>
> Step 3. Install .NET framework via
> [`http://www.microsoft.com/en-us/download/details.aspx?id=21`](http://www.microsoft.com/en-us/download/details.aspx?id=21)
>
> Step 4. Install node via (with default options)
> [`http://nodejs.org/download/`](http://nodejs.org/download/)
>

**OS X**

*Installer method*

> Step 1. Install Xcode via
> [`http://itunes.apple.com/us/app/xcode/id497799835?ls=1&mt=12`](http://itunes.apple.com/us/app/xcode/id497799835?ls=1&mt=12)
>
> Step 2. Install git via
> [`http://code.google.com/p/git-osx-installer`](http://code.google.com/p/git-osx-installer)
>
> Step 3. Install node via
> [`http://nodejs.org/download/`](http://nodejs.org/download/)

*CLI method*

> Step 1. Install command line tools
>
>     xcode-select --install
>
> Then, select "install" when the pop-up window appears.
>
> Step 2. Install macports
>
>     curl -O https://distfiles.macports.org/MacPorts/MacPorts-2.2.1.tar.bz2
>     tar xf MacPorts-2.2.1.tar.bz2
>     cd MacPorts-2.2.1/
>     ./configure
>     make
>     sudo make install
>     sudo ports selfupdate
>
> Step 3. Install git
>
>     sudo port install git-core +svn +doc +bash_completion +gitweb
>
> Step 4. Install Homebrew
>
>     ruby -e "$(curl -fsSL https://raw.github.com/Homebrew/homebrew/go/install)"
>
> Step 5. Install node.js and npm with Homebrew
>
>     brew install node

**Debian / Ubuntu**

> Step 1. Update apt-get
>
>     apt-get update
>
> Step 2. Make sure that `curl`, `make`, `gcc`/`g++`, and `git` are
> installed
>
>     apt-get install curl
>     apt-get install git
>
> *Debian*
>
>     apt-get install make
>     apt-get install build-essential
>
> *Ubuntu*
>
>     apt-get install python-software-properties python g++ make
>
> Step 3. Install node.js and npm
>
> *Debian*
>
>     echo "deb http://ftp.us.debian.org/debian wheezy-backports main" >> /etc/apt/sources.list
>     apt-get install nodejs-legacy
>     curl https://npmjs.org/install.sh | sh
>
> *Ubuntu*
>
>     add-apt-repository ppa:chris-lea/node.js
>     apt-get update
>     apt-get install nodejs
