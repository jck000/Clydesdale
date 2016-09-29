
  function cldl_ajax(to_path, data, method, onsuccess, onfailure) {
    method    = method        || 'get';
    onsuccess = onsuccess     || {};
    onfailure = onfailure     || {};
    http_url  = '[% app_host_url %]' + to_path;
    $.ajax({
             url:         http_url,
             type:        method,
             data:        data,
             failure:     onfailure,
             success:     onsuccess
           });
  }





