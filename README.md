# Structuring a Web App with Spine JS and AMD

## tl;dr

This article will set up a web app using [Yeoman](http://yeoman.io), [Spine](http://spinejs.com), [CoffeeScript](http://coffeescript.org), and [Require JS](http://requirejs.org/) for [Asynchronous Module Definition (AMD)](https://github.com/amdjs/amdjs-api/wiki/AMD) and provide sample code that should be usable for another project.

## Set Up Yeoman

Yeoman is a command line tool that speeds up front-end web app development. First, let's open the terminal and install yeoman, then create a directory for your project and initialize a new yeoman project. I'll refer to your project directory as ~ from now on in file paths. 

```shell
$ yeoman init
```
Then, you'll see:

```shell
Running "init:yeoman" (init) task
This task will create one or more files in the current directory, based on the
environment and the answers to a few questions. Note that answering "?" to any
question will show question-specific help and answering "none" to most questions
will leave its value blank.

"yeoman" template notes:

   invoke  app

     _-----_
    |       |
    |--(o)--|   .--------------------------.
   `---------´  |    Welcome to Yeoman,    |
    ( _´U`_ )   |   ladies and gentlemen!  |
    /___A___\   '__________________________'
     |  ~  |
   __'.___.'__
 ´   `  |° ´ Y `

Out of the box I include HTML5 Boilerplate, jQuery and Modernizr.

Please answer the following:
[?] Would you like to include Twitter Bootstrap for Compass instead of CSS? (Y/n) Y
[?] Would you like to include the Twitter Bootstrap JS plugins? (Y/n) Y
[?] Would you like to include RequireJS (for AMD support)? (Y/n) Y
[?] Would you like to support writing ECMAScript 6 modules? (Y/n) n
[?] Do you need to make any changes to the above before continuing? (y/N) N
```

Make sure to include RequireJS. I also highly recommend including Twitter Bootstrap for Compass instead of CSS. Now use yeoman to install Spine:

```shell
$ yeoman install spine
```

```shell
Running "bower:install:spine" (bower) task
GET https://bower.herokuapp.com/packages/spine
bower cloning git://github.com/maccman/spine.git
bower cached git://github.com/maccman/spine.git
bower fetching spine
bower checking out spine#v1.0.8
bower copying /Users/vailgold/.bower/spine/4fa4cf26fbbf541d61628bb868c135ec
bower installing spine#1.0.8

Done, without errors.
```

Now run the app and make sure you see Yeoman's confirmation page:

```shell
$ yeoman server
```

## Build Spine

Enter ~/app/components/spine/src and run the following command to build the .coffee files into one, which will give you the Spine build for your test server.

```shell
$ cat spine.coffee list.coffee manager.coffee route.coffee relation.coffee ajax.coffee local.coffee > spine-build.coffee
```

If you included Twitter Bootstrap JS plugins with yeoman, then you'll see the following block of HTML in ~/app/index.html. I prefer to just download one file from [Twitter Bootstrap](http://twitter.github.com/bootstrap/) that contains what I want and include it using Require, so I usually remove this code.

```html
<!-- build:js scripts/plugins.js -->
<script src="scripts/vendor/bootstrap/bootstrap-affix.js"></script>
<script src="scripts/vendor/bootstrap/bootstrap-alert.js"></script>
<script src="scripts/vendor/bootstrap/bootstrap-dropdown.js"></script>
<script src="scripts/vendor/bootstrap/bootstrap-tooltip.js"></script>
<script src="scripts/vendor/bootstrap/bootstrap-modal.js"></script>
<script src="scripts/vendor/bootstrap/bootstrap-transition.js"></script>
<script src="scripts/vendor/bootstrap/bootstrap-button.js"></script>
<script src="scripts/vendor/bootstrap/bootstrap-popover.js"></script>
<script src="scripts/vendor/bootstrap/bootstrap-typeahead.js"></script>
<script src="scripts/vendor/bootstrap/bootstrap-carousel.js"></script>
<script src="scripts/vendor/bootstrap/bootstrap-scrollspy.js"></script>
<script src="scripts/vendor/bootstrap/bootstrap-collapse.js"></script>
<script src="scripts/vendor/bootstrap/bootstrap-tab.js"></script>
<!-- endbuild -->
```

The good thing about the code above is that it demonstrates how to use Yeoman's build process to concatenate and minify a script. However, that only occurs when calling `yeoman build`, so it may not be helpful while building the application. Here is what that method would look like for Spine. Make sure to have spine.js at the top of the list, and then the order of the rest doesn't matter.

```html
<!-- build:js scripts/vendor/spine-build.js -->
<script src="components/spine/lib/spine.js"></script>
<script src="components/spine/lib/manager.js"></script>
<script src="components/spine/lib/list.js"></script>
<script src="components/spine/lib/relation.js"></script>
<script src="components/spine/lib/route.js"></script>
<script src="components/spine/lib/ajax.js"></script>
<script src="components/spine/lib/local.js"></script>
<!-- endbuild -->
```

## Configure Font Awesome in Compass

I downloaded [Font Awesome](http://fortawesome.github.com/Font-Awesome/) as a zip archive (I'll refer to this zip archive as ~FA), and I copied the contents of the `~FA/font` to `~/app/fonts`. `~/app/styles/compass_twitter_bootstrap/_font-awesome.scss` is an old version of Font Awesome, so follow these steps:

1. Open `~FA/sass/font-awesome.scss`.
2. Find the last line of `~/app/styles/compass_twitter_bootstrap/_font-awesome.scss in ~FA/sass/font-awesome.scss`.
3. Copy the rest of `~FA/sass/font-awesome.scss` into `~/app/styles/compass_twitter_bootstrap/_font-awesome.scss`.

Then, in ~/Gruntfile.js, add a reference to the fonts directory:

```javascript
    // compile .scss/.sass to .css using Compass
    compass: {
      dist: {
        // http://compass-style.org/help/tutorials/configuration-reference/#configuration-properties
        options: {
          css_dir: 'temp/styles',
          sass_dir: 'app/styles',
          images_dir: 'app/images',
          fonts_dir: 'fonts'
          javascripts_dir: 'temp/scripts',
          force: true
        }
      }
    },
```

In `~/app/styles/main.scss`, change to import statement at the top of the file to:

```sass
@import "compass_twitter_bootstrap_awesome";
```

## Prepare index.html

In `~/app/index.html`, I generally like to have just one div with an ID unique for my application into which I insert the structure of the DOM that I need.

## Prepare Third Party Libraries

I added [jQuery](http://jquery.com/), [Underscore](http://underscorejs.org/), [jQueryUI](http://jqueryui.com/), Bootstrap, [ES5 Shim](https://github.com/kriskowal/es5-shim), [Moment](http://momentjs.com/), [Spin](http://fgnass.github.com/spin.js/), and a [jQuery plugin for file uploads](https://github.com/blueimp/jQuery-File-Upload) to `~/app/scripts/vendor`. I also added [text.js](http://github.com/requirejs/text) to `~/app/scripts`, which will let us import files as text using Require, useful for templating.

## Set Up Application

We're using CoffeeScript, so I converted main.js and app.js to main.coffee and app.coffee. One note of caution is to be careful of any requirements that your libraries have. As an example, the jQuery fileupload plugin requires "jquery.ui.widget" in its own code out of the box, so I had to change that reference to "jquery-ui", which is the name I used in `~/app/scripts/main.coffee`. Also, the RequireJS docs state that setting up paths and shims for a library does not actually load it, which is why `~/app/scripts/main.coffee` loads those libraries explicitly.

Inside of the actual module, we instantiate the App when the document is ready and save it to the global namespace, and then start Spine's Stack (it controls the URL routing) after a master promise resolves, which we'll see in the application definition happens after all model fetching occurs.
