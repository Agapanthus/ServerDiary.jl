# TODO

* New providers
  * collectl
    * Retrieve data: `collectl -P -p /var/log/collectl/vmd46640-20191228-124035.raw.gz`
    * You can have per-process stats
      * Make plot of the n% most time/memory consuming processes
    * Database is here http://collectl.sourceforge.net/Data-detail.html
    * what's the problem with normalisation? http://collectl.sourceforge.net/TheMath.html
  * Aws
    * load `aws ce` data 
      * You must use the following policy: 
      * ```{
        "Version": "2012-10-17",
        "Statement": [
            {
            "Effect": "Allow",
            "Action": [
                "ce:*"
            ],
            "Resource": [
                "*"
            ]
            }
        ]
        }```
      * Beware! You will be charged 0.01$ per request!
        `aws ce get-cost-and-usage --time-period Start=2019-12-01,End=2019-12-24 --granularity DAILY --metrics "BlendedCost" "UnblendedCost" "UsageQuantity" --group-by Type=DIMENSION,Key=SERVICE Type=TAG,Key=Environment --region us-east-1`
    * make sure it is really only called once a day. E.g., write file, make sure it persists (logging will start the second day you use it) and increment it. 
    * Furthermore, you could setup ip tables to block connections `https://ce.us-east-1.amazonaws.com` if there are to many per day
      * Rate-limit, like `--limit 5/day` https://making.pusher.com/per-ip-rate-limiting-with-iptables/
  * IP Tables
  * Pflogsum / Postfix
  * Apache2 Access / Redis / mysql log
* Improve srcCtx-concept
  * Multiplying graphs is good, but we also want to
    * stack lines of different resolution
    * combine lines from different contexts
* make a widget where you can "retrieve, aggregate and stack the most common lines"
  * Useful to display aws usage or the most consuming processes
  * Make sure the order of stacked lines and labels is the same. Currently it is not!
* Report errors during program evaluation in the html / e-mail