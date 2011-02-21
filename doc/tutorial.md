# How to build a Facebook application within Rails 3 using the RestGraph gem

1. Before you start I strongly recommend reading these:

	* Apps on Facebook.com -> [http://developers.facebook.com/docs/guides/canvas/](http://developers.facebook.com/docs/guides/canvas/)
	* Graph API -> [http://developers.facebook.com/docs/reference/api/](http://developers.facebook.com/docs/reference/api/)
	* Authentication -> [http://developers.facebook.com/docs/authentication/](http://developers.facebook.com/docs/authentication/)
	* Heroku: Building a Facebook Application -> [http://devcenter.heroku.com/articles/facebook/](http://devcenter.heroku.com/articles/facebook)
	
	
2. Go to [FB Developers website](http://facebook.com/developers "FB Developers website") and create a new FB app. Set its canvas name, canvas url and your site URL. Set the canvas type to iframe.


3. Build a new Rails application.
		
			rails new <name>


4. Declare RestGraph and its dependencies in the Gemfile. Add these lines:
		
			gem 'rest-graph'

			# for rest-graph
			gem 'rest-client', '>=1.6'
			gem 'json'


5. You will also have to declare the requirement in the /config/environment.rb file. Please add this to the end of the file:
		
			require 'rest-graph/auto_load'


6. Create the rest-graph.yaml file in your /config directory and fill it with your FB app data. If you want to run your application in a canvas, declare the canvas name and set the 'iframe' value to true. If you don't, just don't mention any of these :)

	Example:
		
			development:
				app_id: 'XXXXXXXXXXXXXX'
				secret: 'YYYYYYYYYYYYYYYYYYYYYYYYYYY'
				callback_host: 'my.dev.host.com'	
				
			production:
				app_id: 'XXXXXXXXXXXXXX'
				secret: 'YYYYYYYYYYYYYYYYYYYYYYYYYYY'
				canvas: 'yourcanvasname'
				callback_host: 'my.production.host.com'
				iframe: true

	
	If you push to Heroku your production callback_host should be `yourappname.heroku.com`. You can use a tunnel for your development environment and test your application without struggling to push it to Heroku every time you make some changes. You'll find more information on the tunneling here: [http://tunnlr.com/](http://tunnlr.com/).
	
7. Let's create a first controller for your app - ScratchController.
		
			rails g controller Scratch
	
8. The next step will be to include rest-graph to your controller. You should put these two lines in:
		
			require 'rest-graph/auto_load'
			include RestGraph::RailsUtil
	
	Now you can make use of the RestGraph commands :)
	
9. So now you need to setup the access to your application in the controller. RestGraph can do it for you using the data from your rest-graph.yaml file. All you need to do is to run rest_graph_setup function. Let's use it as a before_filter.

	Add this line after the `include RestGraph::RailsUtil`:
		
			before_filter :setup
	
	And declare setup as a private function:
		
			private
		
			def setup
				rest_graph_setup(:auto_authorize => true)
			end
	
	rest_graph_setup will create a rest_graph object for you; `:auto_authorize` argument tells RestGraph to redirect users to the app authorization page if the app is not authorized yet.
	
	You can now perform all kind of Graph API operations using the rest_graph object.
	
10. Ok! Your controller is ready to make use of all the beauty that comes with RestGraph! You can prepare a first sample action now. 
		
			def me
				render :text => rest_graph.get('me').inspect
			end

11. Save your controller and go to the /config/routes.rb file to set up the default routing. For now you will just need this line:

			match ':controller/:action'
	
12. You can now push your app to Heroku and try to open [http://yourappname.heroku.com/scratch/me](http://yourappname.heroku.com/scratch/me) in your browser. If you are logged in your Facebook account, this address should redirect you to the authorization page and ask if you want to let your application access your private information. After you confirm, you should be redirected straight to your 'me' action which is supposed to show the basic information about you in a hash.

	Tada!
	
13. I guess you are also quite curious about how to get to some other data about your users. It's very easy. You can add another sample action to your controller:

			def feed
				render :text => rest_graph.get('me/home').inspect
			end
	
	If you will push the changes to heroku and go to [http://yourappname/scratch/feed](http://yourappname/scratch/feed), the page should give you a hash with all the data from your feed now.
	

14. Ok. Now let's try to access your Facebook wall. You need to add a new action to your controller:
		
			def wall
				render :text => rest_graph.get('me/feed').inspect
			end
	
	You might wonder why you should access the wall with `me/feed` argument instead of `me/wall`, but unfortunately it's the way FB describes the data. You can access news feeds through `me/home` and users walls through `me/feed` ...
	
	Actually, I need to warn you that this time the action won't work properly. Why? Because users didn't grant you the permission to access their walls! You need to ask them for this special permission and that means you need to add something more to your controller.
	
	So, we will organize all the permissions we need as a scope and pass them to the rest_graph_setup call. I find it handy to make the scope array and declare what kind of permissions I need just inside this array. If you feel it's a good idea, you can add this line to your private setup function, just before you call rest_graph_setup:
		
			scope = []
			scope << 'read_stream'
	
	The only permission you need right now is the 'read_stream' permission. You can find out more about different kinds of user permissions here: [http://developers.facebook.com/docs/authentication/permissions/](http://developers.facebook.com/docs/authentication/permissions/)
	
	You also need to add the auto_authorize_scope argument to the rest_graph_setup. It will look this way now:
		
			rest_graph_setup(:auto_authorize => true, :auto_authorize_scope => scope.join(','))
	
	As you see, you might as well pass the argument like this `:auto_authorize_scope => 'read_stream'`, but once you have to get a lot of different permissions, it's very useful to put them all in an array, because it's more readable and you can easily delete or comment out any one of them.
	
	Ok. Save your work and push it to heroku or just try in your tunneled development environment. /scratch/wall URL should give you the hash with user's wall data now!
	
	Remember. Anytime you need to get data of a new kind, you need to ask user for a certain permission first and that means you need to declare this permission in your scope array!
	
15. What else? If you know how to deal with hashes then you will definitely know how to get any kind of data you want using the rest_graph object. Let's say you want to get a last object from a user's wall (last in terms of time, last posted, so the first on the wall and therefore first to Ruby). Let's take a look at the /scratch/feed page. The hash which is printed on this page has 2 keys - data and paging. Let's leave the paging key aside. What's more interesting here comes as a value of 'data'. So the last object in any user's wall will be simply:

			rest_graph.get('me/feed')['data'].first
	
	Now let's say you want only to keep the name of the author of this particular object. You can get it by using:

			rest_graph.get('me/feed')['data'].first['from']['name']
	
	That's it!