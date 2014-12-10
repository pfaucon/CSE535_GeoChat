
Parse.Cloud.job("calcZoneJob", function(request, status) {
  // Set up to modify user data
  Parse.Cloud.useMasterKey();

  Parse.Cloud.run('calcZones', {}, {
    success: function(result) {
      console.log("calcZones finished");

      Parse.Cloud.run('nameZones', {em_class:result[1]}, {
        success: function(ratings) {
          console.log("nameZones finished");
        },
        error: function(error) {
          console.error('Error calling zoneMessages ' + error.status);
        }
      });
    },
    error: function(error) {
      console.error('Error calling zoneMessages ' + error.status);
    }
  }).then(function(result) {
    console.log(result);
    status.success("calcZoneJob completed successfully.");
    // Set the job's success status
    
  }, function(error) {
    // Set the job's error status
    status.error("Uh oh, something went wrong.");
  });
});


Parse.Cloud.define("calcZones", function(request, response) {
  var result, classes = 3;

  Parse.Cloud.httpRequest({
    method: "GET",
    url: "https://cse535-project.firebaseio.com/Messages.json",
    headers: {
      'Content-Type': "application/json"
    },
    success: function(httpResponse) {
      result = JSON.parse(JSON.stringify(httpResponse));
      console.log("result")
      console.log(result.data);

      var locationData = prepareData(result.data);
      var em_labelvecs = [];
      var em_class = [];
      console.log("location data");
      console.log(locationData);
      em_class.length = 3;

      em_prep(locationData[0], em_labelvecs, em_class);

      for(var i = 0; i < 10; ++i)
      {
        em_expect(locationData[0], em_labelvecs, em_class);
        em_maximize(locationData[0], em_labelvecs, em_class);
      }

      returnResult = [em_labelvecs, em_class, locationData[0], locationData[1]];

      console.log("Calling zoneMessages");

      Parse.Cloud.run('zoneMessages', {em_labelvecs:em_labelvecs, keys:locationData[1], orgData:result.data, loopCounter:1}, {
        success: function(ratings) {
          console.log("Came back to calcZones");
        },
        error: function(error) {
          console.error('Error calling zoneMessages ' + httpResponse.status);
        }
      });

      Parse.Cloud.run('zoneMessages', {em_labelvecs:em_labelvecs, keys:locationData[1], orgData:result.data, loopCounter:2}, {
        success: function(ratings) {
          console.log("Came back to calcZones");
        },
        error: function(error) {
          console.error('Error calling zoneMessages ' + httpResponse.status);
        }
      });

      Parse.Cloud.run('zoneMessages', {em_labelvecs:em_labelvecs, keys:locationData[1], orgData:result.data, loopCounter:3}, {
        success: function(ratings) {
          console.log("Came back to calcZones");
        },
        error: function(error) {
          console.error('Error calling zoneMessages ' + httpResponse.status);
        }
      }).then(response.success(returnResult));
    },
    error: function(httpResponse) {
      console.error('Request failed with response code ' + httpResponse.status);
      response.error('Request failed with response code ' + httpResponse.status);
    }
  });
});

Parse.Cloud.define("nameZones", function(request, response) {
  var _ = require('underscore');
  var em_class = request.params.em_class;

  console.log("em_class");
  console.log(em_class);

  var promises = [];
  var zones = [];

  // Using Underscore.js to interate through em_class, it's just a simple form of a for-loop
  _.each(em_class, function(aClass,i)
  {
    // Putting calls to the JavaScript nameZones function in promise.
    promises.push(zones[i] = nameZones(aClass, i));
  });

  // Executing all the entries in the promise.
  Parse.Promise.when(promises).then(response.success(zones));
});

function nameZones(aClass, i)
{
  var currLoc = aClass;
  var lat = currLoc[0][0];
  var lon = currLoc[0][1];
  var covar_xx = currLoc[1][0];
  var covar_yy = currLoc[1][1];
  var covar_xy = currLoc[1][2];

  var name = encodeURIComponent("zone" + i);
  var zone = {
    "lat" : lat, 
    "lon" : lon, 
    "covar_xx" : covar_xx, 
    "covar_yy" : covar_yy, 
    "covar_xy" : covar_xy
  }; 

  console.log(name);
  console.log(zone);

  Parse.Cloud.httpRequest({
    method: "PUT",
    url: "https://cse535-project.firebaseio.com/Zones/" + name + ".json",
    headers: { 'Content-Type': "application/json"},
    error: function(httpResponse) {
      console.error('Firebase: Request failed with response code ' + httpResponse.status);
      response.error('Firebase: Request failed with response code ' + httpResponse.status);
    },
    body: JSON.stringify(zone)
  });

  return zone;
}

Parse.Cloud.define("zoneMessages", function(request, response) {
  var _ = require('underscore');
  var em_labelvecs = request.params.em_labelvecs;
  var keys = request.params.keys;
  var orgData = request.params.orgData;
  var loopCounter = request.params.loopCounter;

  console.log("zoneMessages started");

  var promises = [];

  if(loopCounter == 1)
  {
    for(var i = 0; i < Math.floor(keys.length / 3); i++)
    {
      var zoneNum;
      var maxVal = -1;
      var message = orgData[keys[i]];

      for(var j = 0; j < em_labelvecs[i].length; j++)
      {
        if(em_labelvecs[i][j] > maxVal)
        {
          zoneNum = j;
          maxVal = em_labelvecs[i][j];
        }
      }

      promises.push(zoneMessages(keys, zoneNum, i, message));
    }
  }

  else if(loopCounter == 2)
  {
    for(var i = Math.floor(keys.length / 3); i < Math.floor(keys.length * (2 / 3)); i++)
    {
      var zoneNum;
      var maxVal = -1;
      var message = orgData[keys[i]];

      for(var j = 0; j < em_labelvecs[i].length; j++)
      {
        if(em_labelvecs[i][j] > maxVal)
        {
          zoneNum = j;
          maxVal = em_labelvecs[i][j];
        }
      }

      promises.push(zoneMessages(keys, zoneNum, i, message));
    }
  }

  else
  {
    for(var i = Math.floor(keys.length * (2 / 3)); i < keys.length; i++)
    {
      var zoneNum;
      var maxVal = -1;
      var message = orgData[keys[i]];

      for(var j = 0; j < em_labelvecs[i].length; j++)
      {
        if(em_labelvecs[i][j] > maxVal)
        {
          zoneNum = j;
          maxVal = em_labelvecs[i][j];
        }
      }

      promises.push(zoneMessages(keys, zoneNum, i, message));
    }
  }

  // for(var i = 0; i < keys.length; i++)
  // {
  //   var zoneNum;
  //   var maxVal = -1;
  //   var message = orgData[keys[i]];

  //   for(var j = 0; j < em_labelvecs[i].length; j++)
  //   {
  //     if(em_labelvecs[i][j] > maxVal)
  //     {
  //       zoneNum = j;
  //       maxVal = em_labelvecs[i][j];
  //     }
  //   }

  //   promises.push(zoneMessages(keys, zoneNum, i, message));
  // }

  // Parse.Promise.when(promises).then(function(i, keys, em_labelvecs) {
  //   promises = [];

  //   for(; i < keys.length; i++)
  //   {
  //     var zoneNum;
  //     var maxVal = -1;
  //     var message = orgData[keys[i]];

  //     for(var j = 0; j < em_labelvecs[i].length; j++)
  //     {
  //       if(em_labelvecs[i][j] > maxVal)
  //       {
  //         zoneNum = j;
  //         maxVal = em_labelvecs[i][j];
  //       }
  //     }

  //     promises.push(zoneMessages(keys, zoneNum, i, message));
  //   }
  // }).when(promises).then(response.success("zoneMessages Done"));

  // Executing all the entries in the promise.
  Parse.Promise.when(promises).then(response.success("zoneMessages Done"));
});

function zoneMessages(keys, zoneNum, i, message)
{
  var zoneName = "zone" + zoneNum;
  message["zone"] = zoneName;

  console.log(zoneName + " " + JSON.stringify(message) + " " + "https://cse535-project.firebaseio.com/Messages/" + keys[i] + ".json");
  
  Parse.Cloud.httpRequest({
    method: "PUT",
    url: "https://cse535-project.firebaseio.com/Messages/" + keys[i] + ".json",
    headers: { 'Content-Type': "application/json"},
    success: function(httpResponse){
      console.log("Firebase zoneMessages success");
      console.log(httpResponse);
    },
    error: function(httpResponse) {
      console.error('Firebase: Request failed with response code ' + httpResponse.status);
      response.error('Firebase: Request failed with response code ' + httpResponse.status);
    },
    body: JSON.stringify(message)
  });
}

function prepareData(rawData)
{
  var result = [];
  var resultKey = [];
  var i = 0; // Counter

  for (var key in rawData)
  {
    if (rawData.hasOwnProperty(key)) 
    {
      temp = [];
      temp[0] = rawData[key]["lat"];
      temp[1] = rawData[key]["lon"];
      result[i] = temp;

      resultKey[i] = key;

      ++i;
    }
  }

  return [result, resultKey];
}

function em_maximize(data, labelvecs, classes) {
  for(var cc = 0; cc < classes.length; ++cc) {
    var sum = [0,0];
    var num = 0;
    for(var dd = 0; dd < data.length; ++dd) {
      var p = labelvecs[dd][cc];
      sum[0] += p * data[dd][0];
      sum[1] += p * data[dd][1];
      num += p;
    }
    
    var mean = [sum[0]/num, sum[1]/num];
    var xx = 0, yy = 0, xy = 0;
    for(var dd = 0; dd < data.length; ++dd) {
      var p = labelvecs[dd][cc];
      var rel = v2_sub_v2(data[dd], mean);
      xx += rel[0]*rel[0] * p;
      xy += rel[0]*rel[1] * p;
      yy += rel[1]*rel[1] * p;

    }
    xx /= num;
    xy /= num;
    yy /= num;
    
    var cov = [xx, xy, xy, yy];
    
    classes[cc][0] = mean;
    classes[cc][1] = cov;
  }  
}

function em_expect(data, labelvecs, classes) {
  // data: array of v2 points
  // labelvecs: probabilistic assignment of data to classes
  // classes: each is a [v2, m22]
  
  // This is described in:
  // http://en.wikipedia.org/wiki/Multivariate_normal_distribution
  // 
  // For every class..
  for(var cc = 0; cc < classes.length; ++cc) {
    // ..compute fixed parameters of probability density function..
    var inv_cov = m22_invert(classes[cc][1]);
    var d = Math.pow(m22_det(classes[cc][1]), -0.5);
    // ..and for every datum..
    for(var dd = 0; dd < data.length; ++dd) {
      var rel = v2_sub_v2(data[dd], classes[cc][0]);
      // ..compute its probability.
      var p = d*Math.exp(-0.5*v2_dot_v2(v2_mul_m22(rel, inv_cov), rel));
      labelvecs[dd][cc] = p;
    }
  }

  // Now normalize so each datum has probability 1.0.
  // Also label each one as its current most likely class.
  for(var dd = 0; dd < data.length; ++dd) {
    var sum = 0;
    var max = 0;
    var maxcc = 0;
    for(var cc = 0; cc < classes.length; ++cc) {
      sum += labelvecs[dd][cc];
      if (labelvecs[dd][cc] > max) {
        max = labelvecs[dd][cc];
        maxcc = cc;
      }
    }
    // labels[dd] = maxcc;
    for(var cc = 0; cc < classes.length; ++cc) {
      labelvecs[dd][cc] /= sum;
    }
  }
}

function em_prep(data, labelvecs, classes) {
  for(var dd = labelvecs.length; dd < data.length; ++dd) {
    labelvecs[dd] = [];
    for(var cc = 0; cc < classes.length; ++cc) {
      labelvecs[dd][cc] = 1.0 / classes.length;
    }
  }
  labelvecs.length = data.length;
  var s = 100;
  for(var cc = 0; cc < classes.length; ++cc) {
    if(classes[cc]) {
      continue;
    }
    classes[cc] = [];
    classes[cc][0] = v2_rand();
    classes[cc][1] = [s, 0, 0, s];
  }
}

function v2_rand() { return [1-2*Math.random(), 1-2*Math.random()]; }
function v2_zero() { return [0,0]; }
function v2_add_v2(a,b) { return [a[0]+b[0],a[1]+b[1]]; }
function v2_addto_v2(a,b) { b[0] += a[0]; b[1] += a[1]; }
function v2_sub_v2(a,b) { return [a[0]-b[0],a[1]-b[1]]; }
function v2_dot_v2(a,b) { return a[0]*b[0]+a[1]*b[1]; }
function v2_len(a) { return Math.sqrt(a[0]*a[0]+a[1]*a[1]); }
function v2_dist_v2(a,b) {
  var dx = a[0]-b[0];
  var dy = a[1]-b[1];
  return Math.sqrt(dx*dx+dy*dy);
}

// 2x2 matrix stored in a 4-element array, column major.
// [ 0 2 ]
// [ 1 3 ]

function m22_ident() { return [1, 0, 0, 1]; }

function v2_mul_m22(v,m) { return [v[0]*m[0]+v[1]*m[2], v[0]*m[1]+v[1]*m[3]]; }

function m22_mul_m22(m,n) {
  return [m[0]*n[0]+m[1]*n[2],
          m[0]*n[1]+m[1]*n[3],
          m[2]*n[0]+m[3]*n[2],
          m[2]*n[1]+m[3]*n[3]];
}
function m22_transpose(m) { return [m[0], m[2], m[1], m[3]]; }

function m22_det(m) { return m[0]*m[3]-m[1]*m[2]; }

function m22_invert(m) {
  var d = m22_det(m);
  return [m[3]/d, -m[1]/d, -m[2]/d, m[0]/d];
}

// 2x2 Cholesky Decomposition.  A trick for drawing ellipses
function m22_chol(m) {
  var sra = Math.sqrt(m[0]);
  return [sra,0,m[1]/sra,Math.sqrt(m[3]-m[1]*m[1]/m[0])];
}

/*********** Working code, temporary comenting out. ***************/
/****** Could be useful in the future, semi-working code for Google Places API ***********/
// Parse.Cloud.define("namingZones", function(request, response) {
//   var name;
//   var placesAPIKey = "AIzaSyDk7SMts1mkbF2u0WQSrSle2EYuGIzC69I";
//   var radius = 50;
//   var url = "https://maps.googleapis.com/maps/api/place/nearbysearch/json?&type=university|school|establishment&location=" + request.params.location.lat + "," + request.params.location.lon + "&radius=" + radius + "&key=" + placesAPIKey;

//   Parse.Cloud.httpRequest({
//     method: "GET",
//     url: url,
//     headers: {
//       'Content-Type': "application/json"
//     },
//     success: function(httpResponse) {
//       console.log(httpResponse);
//       if(httpResponse.data.status == "OK")
//       {
//         if(httpResponse.data.results[1])
//         {
//           result = httpResponse.data.results[1].name;
//         }

//         else
//         {
//           result = httpResponse.data.results[0].name;
//         }
//       }

//       else
//       {
//         result = "Error: No Places Found";
//       }

//       response.success(result);
//     },
//     error: function(httpResponse) {
//       console.error('Google Places API: Request failed with response code ' + httpResponse.status);
//       response.error('Google Places API: Request failed with response code ' + httpResponse.status);
//     }
//   });
// });

// {"-J_EP6ocd_FEuzBRUhHf":{"location":{"lat":33.4233,"lon":-111.939},"message":"CSE 535 Project"},"-J_JCb2zVaYZGz0Ruxvc":{"location":{"lat":18.08502,"lon":100.13311},"message":"Go Devils"},"-J_JE3XPGXeECaWKJtVr":{"location":{"lat":33.42057549033575,"lon":-111.935760159038},"message":"Arizona State University"},"-J_MZ4fD_B4mzsQWNc1e":{"location":{"lat":33.45276928975569,"lon":-112.0671806485504},"message":"John"},"-J_MZ4fSmXl9QayMgFsF":{"location":{"lat":33.45276928975569,"lon":-112.0671806485504},"message":"Nic"},"-JaHapBQPZpZlTxbJ0Zm":{"location":{"lat":33.20080802797657,"lon":-111.9270634745359},"message":"Christophe "},"-JbBI3azSbmj6lfut9OB":{"location":{"lat":33.22717858500166,"lon":-111.9460354094505},"message":"Harsh"},"-JbDwnQeU_kfZfRra_XQ":{"location":{"lat":33.12720587981847,"lon":-111.945996393403},"message":"Phase II"},"Messages":{"-Jc2elabmuiMy2FrdcPT":{"lat":33.42336778330905,"lon":-111.9396456740265,"message":"messages!"},"-Jc2fVDYDVzfvuNyzRL2":{"lat":33.42338254943569,"lon":-111.9397250103069,"message":"hello"},"-Jc2fXzcZDhPM64Qvm3o":{"lat":33.42338262281073,"lon":-111.9397250162667,"message":"hello"},"-Jc2farXYI3N9jLo_CEa":{"lat":33.42329823158933,"lon":-111.9396141109248,"message":"hello"},"-Jc2g68OUBeMOBwuGAgw":{"lat":33.42325918393763,"lon":-111.9395428913665,"message":"Christophe "},"-Jc2hMCha2UhLVaS9igx":{"lat":33.42326990048157,"lon":-111.9395735300484,"message":"test "}}}
