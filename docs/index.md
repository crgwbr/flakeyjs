# Flakey.js Overview

### What's Flakey.js?
Flakey.js is a (yet another) Javascript MVC framework with an emphasis on Model reliability. Flakey.js is targeted towards mobile platforms where solid server connections are not often possible.

Traditionally working with data inside a webapp, for example writing an email or long document, can be dangerous when the internet connection is intermitent. Entire documents can easily be lost. Flakey.js aims to fix this.

### Why shouldn't I just use [ligament.js](https://gist.github.com/313496e6ba9160dc6eb5)?
Unlike most Javascript MVC frameworks, data in Flakey.js is more than just a hashtable representing the models most current state. Instead, a model exists as a set of instructions on how to build it's most current state. Therefore, any transaction of change in the model can be rolled back, and history can easily be viewed. This is ideal for applications with relatively small datasets (note taking apps, personal wiki's, todo lists) where the data itself is more important than raw performance.

* * * * *

### Building an app based on Flakey.js
The reccomended way to build apps with Flakey.js is to write your app in [Coffeescript](http://coffeescript.org/) and use [Browserify](https://github.com/substack/node-browserify) to bundle Flakey.coffee, your app, and other dependancies into a single file. An example of how to do this is found in example/ of Flakey's git repository.

* * * * *

### Compiling Flakey.js
To compile Flakey.js from source:

- nodejs
- npm (normally installed with nodejs)
- cake (normally installed with nodejs)
- coffeescript (`npm install -g coffee-script`)

To compile the sample note taking app (example/*), all of the above plus:

- browserify (`npm install browserify`)
- eco (`npm install -g eco`)

To build Flakey.js, cd to the root of the repository and run: `cake build`. That will concat the files in `src/` into flakey.coffee. Then flakey.coffee is compiled into flakey.js, and finally minified into flakey.min.js using Google's closure compiler.