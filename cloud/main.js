// Use Parse.Cloud.define to define as many cloud functions as you want.
// For example:
Parse.Cloud.define("hello", function(request, response) {
    var result, classes = 3;
 
    Parse.Cloud.httpRequest({
        method: "GET",
        url: "https://cse535-project.firebaseio.com/.json",
        headers: {
            'Content-Type': "application/json"
        },
        success: function(httpResponse) {
            console.log(httpResponse.text);
            result = JSON.parse(JSON.stringify(httpResponse));
 
            var locationData = prepareData(result.data);
            var em_labelvecs = [];
            var em_class = [];
            em_class.length = 3;
 
            em_prep(locationData, em_labelvecs, em_class);
 
            for(var i = 0; i < 5; ++i)
            {
                em_expect(locationData, em_labelvecs, em_class);
                em_maximize(locationData, em_labelvecs, em_class);
            }
 
            Parse.Cloud.httpRequest({
                method: "PUT",
                url: "https://cse535-project.firebaseio.com/emlabelvecs.json",
                headers: { 'Content-Type': "application/json"},
                error: function(httpResponse) {
                    console.error('Request failed with response code ' + httpResponse.status);
                    response.error('Request failed with response code ' + httpResponse.status);
                },
                body: JSON.stringify(em_labelvecs)
            });
 
            Parse.Cloud.httpRequest({
                method: "PUT",
                url: "https://cse535-project.firebaseio.com/emclass.json",
                headers: { 'Content-Type': "application/json"},
                error: function(httpResponse) {
                    console.error('Request failed with response code ' + httpResponse.status);
                    response.error('Request failed with response code ' + httpResponse.status);
                },
                body: JSON.stringify(em_class)
            });
 
            response.success(em_labelvecs);
        },
        error: function(httpResponse) {
            console.error('Request failed with response code ' + httpResponse.status);
            response.error('Request failed with response code ' + httpResponse.status);
        }
    });
});
 
function prepareData(rawData)
{
    var result = [];
    var i = 0; // Counter
 
    for (var key in rawData) 
    {
        if (rawData.hasOwnProperty(key)) 
        {
            temp = [];
            temp[0] = rawData[key]["location"]["lat"];
            temp[1] = rawData[key]["location"]["lon"];
            result[i] = temp;
 
            ++i;
        }
    }
 
    return result;
}
 
function myFunction(p1) {
    var result = {};
    for (var key in p1) {
        if (p1.hasOwnProperty(key)) {
            if(p1[key]["location"]["lat"] > 33 && p1[key]["location"]["lat"] < 33.43)
            {
                result[key] = p1[key];
            }
        }
    }
    return result ;
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
