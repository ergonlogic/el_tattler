<?php

define('TATTLER_THEME', 'tattler_theme');

/**
 * Implementation of hook_profile_details()
 */
function tattler_profile_details() {  
  return array(
    'name' => 'Tattler',
    'description' => st('Install and configure Drupal as a Tattler site.'),
  );
} 

/**
 * Implementation of hook_profile_task_list()
 *
 * Return a list of tasks that this profile supports.
 *
 * @return
 *   A keyed array of tasks the profile will perform during
 *   the final stage. The keys of the array will be used internally,
 *   while the values will be displayed to the user in the installer
 *   task list.
 */
function tattler_profile_task_list() {
  global $conf;
  $conf['site_name'] = 'Tattler (app) Installer';
  $conf['theme_settings'] = array(
    'default_logo' => 0,
    'logo_path' => 'profiles/tattler/logo.png',
  );

  return array(
    'api-info' => st('Collect API Keys'),
    //'configure-buzz' => st('tattler Configuration'),
  );
  
}

/**
 * Implementation of hook_profile_modules()
 */
function tattler_profile_modules() {
  $core_modules = array(
    // Required core modules.
    'block', 'filter', 'node', 'system', 'user',

    // Optional core modules.
    'comment', 'help', 'locale', 'menu', 'openid', 'path', 'taxonomy', 'update',
  );

  $contributed_modules = array(
    'install_profile_api', 'logintoboggan', 'distro_client',
  
    //misc stand-alone, required by others
      //'advanced_help', 
    'flag',/* 'swfobject_api',*/ 'rdf', 'tagadelic', 
    'votingapi', 'plus1', 'tokenauth', 
      //'search', 'search_config',
    
    //date
    'date_api', 'date_timezone', //'date_popup',
  
    //imagecache
    'imageapi', 'imageapi_gd', 'imagecache', 'imagecache_ui',

    //cck
    'content', 'content_copy', 'fieldgroup', 'number', 'optionwidgets', 'text', 'nodereference', 'userreference', 'date',
	
    // Calais
    'calais_api', 'calais', 'calais_tagmods', 'calais_geo',
	
    // Charts
    'charts_graphs', 'charts_graphs_bluff', //'charts_openflash', 'amcharts', 
    
    // Feed API
    'feedapi', 'feedapi_node', 'feedapi_inherit', 'feedapi_source', 'parser_common_syndication', 'feedapi_itemfilter',

    // Custom Page
    'custompage', 'custompage_ui', 

    //views
    'views', 'views_export', 'views_ui', 'views_groupby', 'views_charts', 
	
    // BuzzMonitor
    /*'buzzmonitor', 'buzz_yahoo_terms', 'buzz_topics',*/ 'img_extractor',

    // Tattler
    'tattlerui', 'tattler_trends',
    
    // for testing only
    'devel', 'admin', 'feedapi_dedupe', 'block_ie6',
    'admin_menu' //May sometimes cause some trouble, but seems to be ok for now. knock on the wood
  );

  return array_merge($core_modules, $contributed_modules);
} 

/**
 * Implementation of hook_profile_tasks().
 */
function tattler_profile_tasks(&$task, $url) {
  
  if($task == 'profile') {
    $task = 'api-info';
    drupal_set_title(st('tattler API Configuration'));
    return drupal_get_form('tattler_api_info', $url);
  }
  
  if($task == 'api-info') {
    // This takes a long time, so try to avoid a timeout.
    if (ini_get('max_execution_time') < 120) {
      set_time_limit(120);
    }
    
    // Save values from the API form
    $form_values = array('values' => $_POST);
    system_settings_form_submit(array(), $form_values);
    
    _install_log(t('Start installation'));
    install_include(tattler_profile_modules());

    drupal_set_title(t('Tattler Installation'));
    _tattler_base_settings();
    //_buzz_set_cck_types();
    _tattler_setup_flags();
    _tattler_initialize_settings();
    _tattler_setup_blocks();

    cache_clear_all();
    
    $task = 'profile-finished';
  }
} 

function tattler_profile_final() {
  //menu_cache_clear_all();
  //module_load_include('inc', 'admin_menu');
  //admin_menu_wipe();
//  variable_set('admin_menu_rebuild_links', TRUE);
}

/**
 * Collect all api keys needed.
 */
function tattler_api_info($form_state, $url) {
  $form = array();

  $apikey = array(
    '!apikey' => _install_extlink('API Key', 'http://en.wikipedia.org/wiki/API_key'),
  );  
  $form['intro'] = array(
    '#value' => t('tattler uses several 3rd party web services to provide insight into the stream of information we process.  In order to use these web services, they require that you have registered with each of them and provide an !apikey with your service requests.  On this screen we will collect all of the API Keys used in the tattler platform. ', $apikey),
  );

  $form['calais'] = array(
    '#type' => 'fieldset',
    '#title' => '<b>' . t('OpenCalais') . '</b>',
  );  
  $form['calais']['intro'] = array(
    '#value' => t('OpenCalais is used to automatically tagging the Entities, Events, and Facts in the monitored content.'),
  );
  $form['calais']['calais_api_key'] = array(
    '#type' => 'textfield',
    '#title' => t('API Key'),
    '#default_value' => $form_state['values']['calais_api_key'],
    '#size' => 60,
    '#description' => _install_extlink('Get an OpenCalais Key', 'http://www.opencalais.com/user/register'),
  );
  
  $form['flickr'] = array(
    '#type' => 'fieldset',
    '#title' => '<b>' . t('Flickr') . '</b>',
  );  
  $form['flickr']['intro'] = array(
    '#value' => t('This is used to retrieve Flickr images contained within monitored Topics.'),
  );
  $form['flickr']['img_extractor_flickr_api_key'] = array(
    '#type' => 'textfield',
    '#title' => t('API Key'),
    '#default_value' => $form_state['values']['img_extractor_flickr_api_key'],
    '#size' => 60,
    '#description' => _install_extlink('Get a Flickr API Key', 'http://www.flickr.com/services/api/keys/apply/') . 
                      ' Once you acquire Technorati account, in order to get API Key go to: ' . 
                      _install_extlink('Technorati Developer Central', 'http://technorati.com/developers/apikey.html'),
  );

  $form['technorati'] = array(
    '#type' => 'fieldset',
    '#title' => '<b>' . t('Technorati') . '</b>',
  );    
  $form['technorati']['intro'] = array(
    '#value' => t('Technorati provides a service to lookup information about blog sources that are monitored. It provides a rank and an authority score that are used to rate Sources.'),
  );
  $form['technorati']['feedapi_source_technorati_api_key'] = array(
    '#type' => 'textfield',
    '#title' => t('API Key'),
    '#default_value' => $form_state['values']['feedapi_source_technorati_api_key'],
    '#size' => 60,
    '#description' => _install_extlink('Get a Technorati API Key', 'http://technorati.com/developers/apikey.html'),
  );
  
  $form['compete'] = array(
    '#type' => 'fieldset',
    '#title' => '<b>' . t('Compete.com') . '</b>',
  );      
  $form['compete']['intro'] = array(
    '#value' => t('Compete.com provides traffic ranking numbers on content Sources. This is also used to help rate Sources.'),
  );
  $form['compete']['feedapi_source_compete_api_key'] = array(
    '#type' => 'textfield',
    '#title' => t('API Key'),
    '#default_value' => $form_state['values']['feedapi_source_compete_api_key'],
    '#size' => 60,
    '#description' => _install_extlink('Get a Compete.com API Key', 'https://my.compete.com/registration/'),
  );
  
  
  /** @deprecated
  
  $form['alexa'] = array(
    '#type' => 'fieldset',
    '#title' => '<b>' . t('Alexa Web Information Service') . '</b>',
  );      
  $form['alexa']['intro'] = array(
    '#value' => t('Alexa provides an alternate traffic ranking service that is also used in computing Source ratings.'),
  );
  $form['alexa']['feedapi_source_aws_access_key_id'] = array(
    '#type' => 'textfield',
    '#title' => t('Access Key'),
    '#default_value' => $form_state['values']['feedapi_source_aws_access_key_id'],
    '#size' => 60,
    '#description' => _install_extlink('Get Alexa Access', 'http://aws-portal.amazon.com/gp/aws/developer/subscription/index.html?productCode=AlexaWebInfoService'),
  );
  $form['alexa']['feedapi_source_aws_secret_access_key'] = array(
    '#type' => 'textfield',
    '#title' => t('Secret'),
    '#default_value' => $form_state['values']['feedapi_source_aws_secret_access_key'],
    '#size' => 60,
    '#description' => _install_extlink('Get Alexa Access', 'http://aws-portal.amazon.com/gp/aws/developer/subscription/index.html?productCode=AlexaWebInfoService'),
  ); **/
  
  $form['submit'] = array(
    '#type' => 'submit',
    '#value' => st('Save and continue'),
  );
  
  $form['#action'] = $url;
  $form['#redirect'] = FALSE;
  return $form;
}

function tattler_api_info_submit($form, &$form_state) {
  // Don't think this ever gets called.
}

// Create an external link
function _install_extlink($text, $url) {
  return l(t($text), $url, array('attributes' => array('target' => '_blank')));
}

/**
 * First function called by install process, just do some basic setup
 */
function _tattler_base_settings() {  
  $types = array(
    array(
      'type' => 'page',
      'name' => st('Page'),
      'module' => 'node',
      'description' => st("A <em>page</em> is a simple method for creating and displaying information that rarely changes, such as an \"About us\" section of a website. By default, a <em>page</em> entry does not allow visitor comments and is not featured on the site's initial home page."),
      'custom' => TRUE,
      'modified' => TRUE,
      'locked' => FALSE,
      'help' => '',
      'min_word_count' => '',
    ),   
  );

  foreach ($types as $type) {
    $type = (object) _node_type_set_defaults($type);
    node_type_save($type);
  }

  // Default page to be promoted and have comments disabled.
  variable_set('node_options_page', array('status'));
  variable_set('comment_page', COMMENT_NODE_READ_WRITE);

  // Theme related.  
  install_default_theme('tattler_theme');
  install_admin_theme('tattler_theme');	
  variable_set('node_admin_theme', FALSE); // Do NOT edit nodes with admin theme!
  
  $theme_settings = variable_get('theme_settings', array());
  $theme_settings['toggle_node_info_page'] = FALSE;
  variable_set('theme_settings', $theme_settings);    

  $TATTLER_THEME_settings = array(
    'toggle_logo' => 0,
    'toggle_name' => 0,
    'toggle_slogan' => 0,
    'toggle_mission' => 0,
    'toggle_node_user_picture' => 0,
    'toggle_comment_user_picture' => 0,
    'toggle_search' => 0,
    'toggle_favicon' => 1,
    'toggle_primary_links' => 1,
    'toggle_secondary_links' => 1,
    'default_logo' => 0,
    'logo_path' => '',
    'logo_upload' => '',
    'default_favicon' => 1,
    'favicon_path' => '',
    'favicon_upload' => '',
    'popups_theme' => 'tattler_theme',
  );
  variable_set('theme_tattler_settings', $TATTLER_THEME_settings);    
  

  // Only site admins can create accounts
  variable_set('user_register', 0);    
  
  // Do not store RDF data locally, it causes huge storage expense
  variable_set('calais_store_rdf', 0);

  _install_log(t('Configured basic settings'));
}


/**
 * Setup the flag definitions
 */
function _tattler_setup_flags() { 

  // Set options on the default bookmark flag
  $bm = flag_get_flag('bookmarks');
  $bm->name = 'bookmark';
  $bm->title = 'Bookmark';
  $bm->roles = array(DRUPAL_AUTHENTICATED_RID);
  $bm->types = array('mention');
  $bm->global = 1;
  $bm->show_on_page = 0;
  $bm->show_on_teaser = 0;
  $bm->i18n = FALSE;
  $bm->save();

  _install_log(t('Flags are configured'));
}  

/**
 * Set roles and permissions and other misc settins
 */
function _tattler_initialize_settings(){
  
  // Clear out existing perms
  db_query('DELETE FROM {permission} WHERE rid = %d', DRUPAL_ANONYMOUS_RID);
  db_query('DELETE FROM {permission} WHERE rid = %d', DRUPAL_AUTHENTICATED_RID);
  
  install_add_permissions(DRUPAL_ANONYMOUS_RID, array());		
  install_add_permissions(DRUPAL_AUTHENTICATED_RID, array(
    'display drupal links',
    'access calais', 
    'access comments', 
    'post comments', 
    'post comments without approval', 
    'view imagecache buzz_photos', 
    'view imagecache mention_photos',
    'access content',
    'vote on content', 
    'access all views', 
    'search content',
    'access tokenauth',
  ));		
		
  // Add all permissions for admin
  $admin_rid = install_add_role('administrator');
  $perms = array();
  foreach (module_list(TRUE, FALSE, TRUE) as $module) {
    if ($permissions = module_invoke($module, 'perm')) {
      $perms = array_merge($perms, $permissions);
    }
  }
  //Admin_menu module does not get enabled during install, so these may get missed.
  install_add_permissions($admin_rid, array(
    'access administration menu',
    'display drupal links',
  ));
  
  // Imagecache has problems
  $perms = array_merge($perms, array('view imagecache buzz_photos', 'view imagecache mention_photos'));
  install_add_permissions($admin_rid, $perms);

  // Permissions for analysts
  $analyst_rid = install_add_role('analyst');
  install_add_permissions($analyst_rid, array(
    'display drupal links',
    'administer blocks',
    'administer tattler',
    'administer feedapi_dedupe',
    'access calais', 
    'access calais rdf', 
    'administer calais', 
    'access comments', 
    'administer comments', 
    'post comments', 
    'post comments without approval', 
    'edit custompage tiles', 
    'administer feedapi', 
    'advanced feedapi options', 
    'view imagecache buzz_photos', 
    'view imagecache mention_photos',
    'translate interface', 
    'access content',
    'administer nodes',
    'create feed content',
    'create mention content',
    'create page content',
    'create source content',
    'create topic content',
    'delete any feed content',
    'delete any mention content',
    'delete any page content',
    'delete any source content',
    'delete any topic content',
    'delete own feed content',
    'delete own mention content',
    'delete own page content',
    'delete own source content',
    'delete own topic content',
    'edit any feed content',
    'edit any mention content',
    'edit any page content',
    'edit any source content',
    'edit any topic content',
    'edit own feed content',
    'edit own mention content',
    'edit own page content',
    'edit own source content',
    'edit own topic content',
    'delete revisions',
    'revert revisions',
    'view revisions',
    'administer url aliases',
    'create url aliases',
    'vote on content', 
    'access RDF data',
    'access user profiles',
    'change own username',
    'access all views', 
    'search content',
    'use advanced search',
    'use keyword search',
    'search by node type',
    'search by category',
    'access tokenauth',
  ));		

  // User pending approval (login toboggan)
  $pending_rid = install_add_role('pending approval user');
  install_add_permissions($pending_rid, array());		

  // Put UID = 1 into the administrator role
  db_query('INSERT INTO {users_roles} (uid, rid) VALUES (%d, %d)', 1, $admin_rid);

  // Login Toboggan Settings
  variable_set('logintoboggan_confirm_email_at_registration', TRUE);
  variable_set('logintoboggan_immediate_login_on_register', TRUE);
  variable_set('logintoboggan_login_successful_message', FALSE);
  variable_set('logintoboggan_login_with_email', TRUE);
  variable_set('logintoboggan_minimum_password_length', 0);
  variable_set('logintoboggan_pre_auth_role', $pending_rid);
  variable_set('logintoboggan_purge_unvalidated_user_interval', 0);
  variable_set('user_email_verification', TRUE); // This is Set Password
  variable_set('site_403', 'toboggan/denied');
  
  // Date-time settings
  variable_set('configurable_timezones', 0);
  variable_set('date_default_timezone', 14400);
  variable_set('date_default_timezone_name', 'America/New_York');
  variable_set('date_first_day', '1');
  
  // Custom Page
  $custompage_config = array (
    'trends' => (object)array(
      'title' => 'Trends',
      'key' => 'trends',
      'path' => 'trends',
      'enabled' => 1,
    ),
    'sources' => (object)array(
      'title' => 'Sources',
      'key' => 'sources',
      'path' => 'sources',
      'enabled' => 1,
    ),
    'termpage' => (object)array(
      'title' => 'Mentions By Term',
      'key' => 'termpage',
      'path' => 'taxonomy/term/%',
      'enabled' => 1,
    ),
    'topics' => (object)array(
      'title' => 'Topics',
      'key' => 'topics',
      'path' => 'topics',
      'enabled' => 1,
    ),    
  );
  variable_set('CUSTOMPAGE_UI_CONFIG', $custompage_config);
  variable_set('custompage_inline_edit', TRUE);
  variable_set('custompage_theme_prefix', '');

  //Calais Settings
  $calais_all = calais_api_get_all_entities();
  $calais_ignored = array('URL');
  $calais_used = array_diff($calais_all, $calais_ignored);
    
  variable_set('calais_api_allow_searching', FALSE);
  variable_set('calais_api_allow_distribution', FALSE);
  variable_set('calais_applied_entities_global', drupal_map_assoc($calais_used));

  $calais_entities = calais_get_entity_vocabularies();
  variable_set('calais_node_feed_process', 'NO');
  variable_set('calais_node_page_process', 'NO');
  variable_set('calais_node_source_process', 'NO');
  variable_set('calais_node_topic_process', 'NO');
  variable_set('calais_node_mention_process', 'AUTO');
 
  variable_set('calais_threshold_mention', '.1');
  
  // Config mentions to use SemanticProxy by default
  variable_set('calais_semanticproxy_field_mention', 'calais_feedapi_node');
  variable_set('calais_semanticproxy_document_mention', 'field_fulltext');
  
  $calais_entities = calais_get_entity_vocabularies();
  $node_types = array('mention');
  foreach($node_types as $key) {
    if(!empty($calais_entities)) {
      foreach ($calais_entities as $entity => $vid) {
        if (!in_array($entity, $calais_ignored)) {
          db_query("INSERT INTO {vocabulary_node_types} (vid, type) values('%d','%s') ", $vid, $key);
        }
      }
    }
  }
 
  // Calais Tagmods
  variable_set('calais_tag_blacklist', '');
  
  // Feed Sources
  //variable_set('feedapi_source_alexa_rank_weight', '1');
  variable_set('feedapi_source_compete_rank_weight', '1');
  variable_set('feedapi_source_technorati_rank_weight', '1');
  
  // Plus1
  variable_set('plus1_in_full_view', TRUE);
  variable_set('plus1_in_teaser', FALSE);
  variable_set('plus1_javascript_settings', TRUE);
  variable_set('plus1_nodetypes', array('mention'));
  variable_set('plus1_you_voted', 'Voted');
		
  // Search_config
  variable_set('search_config_default_search', 'node');
  variable_set('search_config_disable_category', array());
  variable_set('search_config_disable_category_all', 1);
  variable_set('search_config_disable_index_type', array
   (
       'page' => page,
       'topic' => topic,
       'feed' => 0,
       'mention' => 0,
       'source' => 0,
   )); 
  variable_set('search_config_disable_negative', 0);
  variable_set('search_config_disable_or', 0);
  variable_set('search_config_disable_phrase', 0);
  variable_set('search_config_disable_type',  array
   (
       'page' => page,
       'topic' => topic,
       'all' => 0,
       'feed' => 0,
       'mention' => 0,
       'source' => 0,
   )); 
   
  //TokenAuth
  variable_set('tokenauth_length', 32);
  variable_set('tokenauth_pages', "*rss/mentions*");
  
  // Distro server
  variable_set('distro_tracker_server', 'http://tracker.tattlerapp.com/distro/components');
  
  //Performance settings
  variable_set('cache', 1); //Normal level, recommended for production
  variable_set('preprocess_css', 1);
  variable_set('preprocess_js', 1); 
	
  // Basic Drupal settings.
  variable_set('site_frontpage', 'node');
  variable_set('site_name', 'Tattler | Semantic Mining of News and Trends');
 
  _install_log(t('Roles, permissions and configuration settings are in place'));
}

/**
 * Setup/disable blocks
 */
function _tattler_setup_blocks() {

  // Setup the right theme for block initialization
  global $theme_key; 
  $theme_key = TATTLER_THEME;

  // Load all blocks from modules (including views)
  cache_clear_all();
  _block_rehash();
 
  install_set_block('views', 'buzz_photos-block_1', TATTLER_THEME, 'right_sidebar', -10);
  install_add_block_role('views', 'buzz_photos-block_1', DRUPAL_AUTHENTICATED_RID);
  db_query("UPDATE {blocks} SET pages = '%s', visibility = 0 WHERE module = 'views' AND delta = 'buzz_photos-block_1' AND theme = '%s'", '*buzz/*/edit
*admin/*
*trends*', TATTLER_THEME);  

/** Disabled 

  install_set_block('views', 'term_frequency-block_1', TATTLER_THEME, 'right_sidebar', -9);
  install_add_block_role('views', 'term_frequency-block_1', DRUPAL_AUTHENTICATED_RID); 

**/


  install_set_block('views', 'sources-block_2', TATTLER_THEME, 'right_sidebar', -8);
  install_add_block_role('views', 'sources-block_2', DRUPAL_AUTHENTICATED_RID);
  db_query("UPDATE {blocks} SET pages = '%s', visibility = 0 WHERE module = 'views' AND delta = 'sources-block_2' AND theme = '%s'", '*buzz/*/edit
*admin/*
*trends*', TATTLER_THEME);  


/** Disabled 

  install_set_block('views', 'buzzfeeds-block_1', TATTLER_THEME, 'right_sidebar', -7);
  install_add_block_role('views', 'buzzfeeds-block_1', DRUPAL_AUTHENTICATED_RID);

**/

  install_disable_block('user', '0', TATTLER_THEME);
  install_disable_block('user', '1', TATTLER_THEME);
  install_disable_block('system', '0', TATTLER_THEME);
  
  _install_log(t('Blocks initialized and configured'));
}

/**
 * Some logging during the install process
 */
function _install_log($msg) {
  error_log($msg);
  drupal_set_message($msg);
}
