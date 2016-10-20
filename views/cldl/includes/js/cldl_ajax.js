
  function cldl_ajax(to_path, data, method, onsuccess, onfailure, datatype) {
    method    = method    || 'get';
    onsuccess = onsuccess || {};
    onfailure = onfailure || {};
    datatype  = datatype  || 'json';
    http_url  = to_path;
    $.ajax({
             url:         http_url,
             type:        method,
             dataType:    datatype,
             data:        data,
             success:     onsuccess,
             failure:     onfailure
           });
  }





