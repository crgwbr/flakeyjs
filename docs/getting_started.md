#### Building an app based on Flakey.js
The recommended way to build apps with Flakey.js is to write your app in [Coffeescript](http://coffeescript.org/) and use [Browserify](https://github.com/substack/node-browserify) to bundle Flakey.coffee, your app, and other dependancies into a single file. An example of how to do this is found in example/ of Flakey's git repository.

* * * * *

#### Compiling Flakey.js
To compile Flakey.js from source:

- nodejs
- npm (normally installed with nodejs)
- cake (normally installed with nodejs)
- coffeescript (`npm install -g coffee-script`)

To compile the sample note taking app (example/*), all of the above plus:

- browserify (`npm install browserify`)
- eco (`npm install -g eco`)

To build Flakey.js, cd to the root of the repository and run: `cake build`. That will concat the files in `src/` into flakey.coffee. Then flakey.coffee is compiled into flakey.js, and finally minified into flakey.min.js using Google's closure compiler.