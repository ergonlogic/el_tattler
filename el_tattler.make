core = "6.x"
api = "2"

; include Pressflow core
includes[pressflow] = "http://github.com/ergonlogic/Makefiles/raw/master/el_pressflow.make"

; get profile from github
projects[tattler][type] = "profile"
projects[tattler][download][type] = "git"
projects[tattler][download][url] = "git://github.com/ergonlogic/el_tattler.git"

; module dependencies

projects[] = admin
projects[] = admin_menu
projects[] = block_ie6
projects[] = buzzmonitor
projects[] = cck
projects[] = charts_graphs
projects[] = custompage
projects[] = date
projects[] = devel
projects[] = distro
projects[] = feedapi
projects[] = feedapi_dedupe
projects[] = feedapi_itemfilter
projects[] = flag
projects[] = imageapi
projects[] = imagecache
projects[] = install_profile_api
projects[] = logintoboggan
projects[] = opencalais
projects[] = plus1
projects[] = rdf
projects[] = search_config
projects[] = swfobject_api

libraries[swfobject][download][type] = "file"
libraries[swfobject][download][url] = "http://swfobject.googlecode.com/files/swfobject_2_2.zip"
libraries[swfobject][destination] = "modules/swfobject_api"

projects[] = tagadelic
projects[] = tattlerapp
projects[] = tokenauth
projects[] = views
projects[] = views_charts
projects[] = views_groupby
projects[] = votingapi

; theme dependencies
projects[] = tattler_theme
projects[] = rootcandy
