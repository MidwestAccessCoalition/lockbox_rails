# Codebase Overview
## Project board on Github
We use a Github project board to track tickets and progress for the Lockbox app:
https://github.com/MidwestAccessCoalition/lockbox_rails/projects/1

Typically, there will be tickets with the label `good first issue`. If there are none in the `TO DO` column on the project board and you're just super excited to dive in, feel free to contact Nicole for some direction.

## Rails Overview
### Setup and first steps
Getting started with Rails: [the Official Documentation™](https://guides.rubyonrails.org/getting_started.html).

A non-profit educational organization called RailsBridge has a really good [first-time environment setup tutorial](https://docs.railsbridge.org/installfest). This can help to supplement the install instructions in our [`README`](../README.md) in case you get stuck. But also, don't hesitate to contact us for help with local env setup.

RailsBridge's intro to Rails tutorial called `Suggestotron` is also quite good: [Suggestotron tutorial](https://docs.railsbridge.org/intro-to-rails).

(And btdubs, [RailsBridge](https://railsbridge.org) is just and awesome organization in general! And they have other great [tutorials and docs](https://docs.railsbridge.org/docs/) too! You should check them out.)

If you get stuck at any point of the install process, ping Scott or Nicole on Slack or by email, or create an issue on this Github repo. 

### The Rails Way™
Rails has two major principles:
* **Don't Repeat Yourself (aka DRY)**  
When you can re-use code, you should re-use code. Writing DRY code makes the codebase more maintainable, more extensible, and less buggy.
* **Convention** Over **Configuration (or, Rails is Opinionated)**  
This just means that rather than manually configuring every little detail, Rails generates a lot of boilerplate code with reasonable defaults. It also means that when developing in Rails, there is usually a right way and a not-so-right way to do things. Learning `The Rails Way™` of doing things will make your life easier, happier, and more fulfilling.  
That said, there are ways of manually configuring nearly everything, but if you find yourself doing this a lot, you're probably not doing it The Rails Way™ and should re-evaluate some of your life choices.

### MVC Architecture
Rails is an MVC (model-view-controller) framework for web development.

This means that for any resource that a user can view, create, edit, and/or delete, there will likely be the following:
* **Model**: this allows you to interact with the data in a database table with a similar name.  
E.g. the `Cat` model found at `app/model/cat.rb` will allow you to work with records in the `cats` table in your database.  
[_Note that the model is capitalized and singular (`Cat`) and the table name is lowercase and plural (`cats`). These are just two of the many Rails `conventions` introduced above. Nearly everything in the app that can be named follows a set of naming conventions that—once you understand them—will make working with the codebase and database less mysterious and more intuitive._]
* **Controller**: this has several methods which perform specific actions to manipulate the relevant database table through the corresponding model, each based on the [RESTful route (also known as CRUD route)](https://en.wikipedia.org/wiki/Create,_read,_update,_and_delete) that initiated the current request-response cycle.  
E.g. the `CatsController` found at `app/controllers/cats_controller.rb` would contain methods that access the `cats` table in the database through the `Cat` model. Navigating to `https://my-rails-app.com/cats` would call the `CatsController#index` method which retrieves the list of all cats from the database via the `Cat` model.
* **View** this is the presentational code that gets processed to create the code returned to the frontend and displayed in the browser. (This is usually `HTML`, but can be other formats such as `JSON`.)  
E.g. navigating to `https://my-rails-app.com/cats.html` would return an `HTML` page with a list of all `Cat` objects in the DB, possibly formatted and styled as a `<ul>` or a `<table>`. The view file would be found at `app/views/cats/index.html`). There are several different templating languages that can be used to minimize the amount of raw `HTML` that has to be written. By default, Rails uses `ERB` (aka embedded Ruby) in new projects, and this is what we use in the Lockbox App.  
Views set in controller actions are often just a small part of the total response body sent to the browser. Views are typically contained within `layouts` (see the `app/views/layouts/` directory) which can be set in controllers at the top-level to apply to all of that controller's actions, or within each action individually. Layouts and views may be nested, though nested views are often referred to as `partials` and have slightly different invoking methods and naming conventions (the filename has a leading underscore, e.g. `app/views/cats/_cat_description.html.erb`). The primary use case for `partials` is to "DRY (Don't Repeat Yourself) up" your views by extracting `HTML` snippets to be reused in several different views. So you might have an `HTML` snippet the displays the details of a cat object. Then you can place this into a `_cat_details.html.erb` partial that can then be included in your `app/views/cats/show.html.erb` file for relaying details of one cat, but also use it in a loop in your `app/views/cats/index.html.erb` file to iteratively display the details of all the cats.

### DB
#### Schema
The schema file located at `db/schema.rb` provides information about the structure of the DB, its tables, and their columns. Perusing this file is a good way to familiarize yourself with how the database is set up and what information is stored there.

**NOTE: YOU SHOULD NEVER EDIT A SCHEMA FILE DIRECTLY**

#### Migrations
The schema file gets updated each time you [create and run a migration](https://guides.rubyonrails.org/getting_started.html#database-migrations). These files are typically generated by running a `rails` command in a terminal and are kept in the `db/migrate/` directory.

Migrations are used to create, modify, or remove tables and/or table columns. They are used to make and track changes to the DB structure and allow for easy rollback in case the change introduces unforeseen problems.

**NOTE: ONCE A MIGRATION HAS BEEN PUSHED TO GITHUB, YOU SHOULD NOT EDIT IT!**

Editing a migration that someone else may have already pulled into their local dev environment will create major problems for that user. If you made a mistake in a migration and it has already been pushed to `origin` or merged to `trunk`, simply create a new migration to correct the earlier problematic one.

### Basic request/response flow
The basic flow for a single request/response cycle is:
```
routes -> controller#action -> model/DB -> view
```

#### Routes
By default, Rails apps use REST (or CRUD) APIs. Non-RESTful routes may be used as well, but should be kept to a minimum to maintain consistency wherever possible (because The Rails Way™).

The `config/routes.rb` file contains the list of possible paths a user of the app could hit. But because Rails handles a lot of the boilerplate for us, that file won't always make sense until you understand that various helper methods in use. For a more explicit list of the exposed endpoints, running `bundle exec rails routes` will produce a comprehensive list of the app's routes in the following format:
```
Prefix   | Verb  | URI Pattern             | Controller#Action
--------------------------------------------------------------
cats     | POST  | cats(.:format)          | cats#create
edit_cat | GET   | cats/:id/edit(.:format) | cats#edit
cat      | GET   | cats/:id(.:format)      | cats#show
         | PATCH | cats/:id(.:format)      | cats#update
         | PUT   | cats/:id(.:format)      | cats#update
```
* **Prefix** is a pattern used in various Rails helper methods to generate path-related values for you (e.g. the helper `cats_path` would produce the string `/cats` that could be used in the `href` of an `<a>` tag or as the route in a redirect action). For any entry that doesn't have a `prefix` value, that means it is the same as the most recent `prefix` above it. So in the above table, `cat` would be the same `prefix` used for each of the last three lines.
* **Verb** is the HTTP verb sent in the request. This distinguishes a `GET /cats` request that returns a list of cats from a `POST /cats` request that contains data used to create a new cat in the database. (Note that `PATCH` and `PUT` were originally intended for two similar but distinct uses, but are treated as synonymous in most modern RESTful APIs).
* **URI Pattern** is what the router uses to determine what controller and controller action to route the request to. Any part of the path that is prefixed with a colon (`:`) means that section of the path is dynamic, and the dynamic value will be assigned to a variable named `id`.  
So the `cats/:id` pattern will match both `cats/1` and `cats/fluffy`, and will pass a variable called `params` to the controller which will contain a property called `:id` that in the first case will be set to `1`, and in the second case will be set to `fluffy`. 
* **Controller#Action** column specifies what controller the router will send the request to, and what action it will call. This is another place where the Rails naming conventions come into play. In our above table `cats#index` means the router will call the `index` method found in the `CatsController`. 

Putting it all together, navigating in the browser to `https://my-rails-app.com/cats/123` will send a `GET` request to the router that matches the `cats/:id` pattern that will then call the `show` method on the `CatsController` and that method will have access to a `params` object (basically a Hash) that contains `:id => 123`. (This is slightly oversimplified, but the idea here is just to get the basic concepts.)

#### Models
Models contain basic business logic for working with data stored in the corresponding database table. One of the purposes of models is to keep our controllers from becoming overly bloated with business logic. (Rails prefers the "skinny controllers" pattern.)

So our `cats` table might have the columns `name`, `weight_in_lbs`, `color`, `breed` among others. If there were several places in our app that we'd want to convey that info in a human-readable format, our `Cat` model could have a method called `description` that puts them all together for us:
```rb
class Cat
  def description
    "#{name} is a #{color} #{breed} who weighs #{weight_in_lbs} pounds."
  end
end
```

This way in our views, whenever we need this complex string, we can call the `description` method on our cat instance to get something like:
> Whiskers is a black and orange Toyger who weighs 9.2 pounds.

The other primary purpose of models is to perform validations on our data to ensure that any required info is not missing or that data provided matches the expected format. Our database will also perform it's own set of validations, this is both an additional line of defense, and allows us to create more complex types of validations beyond the finite set or length/presence/type validations that databases typically support.

#### Complex model actions/interactions
For concepts larger than a single model or that affect more than one model, a slightly different approach can be used. In the Lockbox app, a `support_request` is a fairly complex concept that involves interactions between a number of different models. The actions needed to create and update a `support_request` live in the `lib/` directory in individual files that describe their function, e.g. `lib/update_support_request.rb`.

This allows us to extract complicated logic from our model which makes the model more maintainable and extensible. It also helps to reduce the amount of tight coupling of models that would otherwise occur in our app.

## The Lockbox App
### Authentication
Auth is handled by the `devise` gem ([what's a gem?](https://guides.rubygems.org/what-is-a-gem/)). In the `ApplicationController` which every other controller inherits from, the very first line is a `before_action` (just a sort of hook that runs before the method being called runs):
```rb
before_action :authenticate_user!
```
This action ensures that nothing can occur until Rails has confirmed that the current request has been sent by authenticated user. If not, the `before_action` will redirect the user, usually to a login or splash screen of some kind.

For those few routes that do not require authentication (such as a "Contact Us" page), a controller may override the `ApplicationController`'s `before_action` hook with a `skip_before_action` hook:
```rb
skip_before_action :authenticate_user!
```

These hooks can be further limited to only run for a subset of a controller's actions. E.g. our made-up `CatsController` might have a `set_current_cat` method that retrieves the relevant cat data from the database which runs before `show`, `update`, `edit`, and `delete`. It wouldn't make sense to try and run this `before_actoin` before the `index`, `new`, or `create` methods since those methods don't work with an individual cat object that already exists in the database (and so would actually throw errors when the non-existant cat isn't found). So in this case, our controller could use either of these two options:
```rb
before_action :set_current_cat, only: [:show, :edit, :update, :delete]
before_action :set_current_cat, except: [:index, :new, :create]
```

### Assets
#### Javascript
Rails 6 uses Webpack by default for asset management. This is a major departure from previous versions of Rails that used something magical and mysterious known as [The Asset Pipeline](https://guides.rubyonrails.org/v5.2/asset_pipeline.html). I only mention this so that if you find yourself troubleshooting an assets issue and see mention of The Asset Pipeline, it's probably not the right solution for your problem. Be sure to add `"rails 6"` in quotes or `"rails" "webpack"` when Google searching asset-related issues.

Distinguishing two related terms:
* **Webpack**: a static module bundler for Javascript  
Webpack is pretty much an industry standard at this point and provides support for a number of tasks previously accomplished through tools such as `grunt` or `gulp`
* **Webpacker**: a Ruby gem that wraps Webpack for use in Rails apps

#### Stylesheets
The Lockbox app supports the use of `CSS`, `SCSS`, and `SASS` file types for styling. All style rules are contained in files in the `app/assets/stylesheets/` directory. At the present, rules are dispersed across a number of files, grouped according to the part of the app they pertain to. However ultimately each of these files is imported into `application.scss` which is then compiled into a single style sheet, meaning rules written overly broadly could inadvertently affect other parts of the app. So err on the side of overly-specific in your rule writing.

#### Images
Images also live in the assets directory. These are loaded by Webpacker and made available across the app through various Rails helper methods (such as `image_tag`) or by referencing in stylesheets.

#### Fonts
Fonts can be included in the assets directory to be handled by Webpack. However in the Lockbox app, we use a gem called `font-awesome-rails` that facilitates the usage of the Font Awesome icon library and provides helper methods for using them in view files, and our standard site-wide fonts are sourced from Google Fonts in a `<script>` tag in `app/views/application.html.erb`.
