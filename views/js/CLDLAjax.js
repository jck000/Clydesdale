
  function cldl_ajax(to_path, data, method, onsuccess, onfailure) {
    method    = method        || 'get';
    onsuccess = onsuccess     || {};
    onfailure = onfailure     || {};
    $.ajax({
             url:         '[% app_host_url %]/[% to_path %]',
             type:        method,
             data:        data,
             failure:     onfailure,
             success:     onsuccess
           });
  }

