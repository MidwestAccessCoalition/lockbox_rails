// This file is automatically compiled by Webpack, along with any other files
// present in this directory. You're encouraged to place your actual application logic in
// a relevant structure within app/javascript and only use these pack files to reference
// that code so it'll be compiled.

require('@rails/ujs').start();
require('turbolinks').start();
//require('@rails/activestorage').start();
require('babel-polyfill');
require('channels');
require('cocoon-js');
// jQuery, Bootstrap, and dataTables need to be loaded in a specific order to work properly.
// See: https://stackoverflow.com/a/61239503/3251463
require('jquery')
require('bootstrap/dist/js/bootstrap')
window.$ = $
require('imports-loader?define=>false!datatables.net')(window, $)
require('imports-loader?define=>false!datatables.net-bs4')(window, $)

require('../src/alerts');
require('../src/notes');
require('../src/admin_dashboard');
require('../src/pending_support_requests_table');
require('../src/tooltips');
require('../src/transactions');
require('../src/url_switching_select');
