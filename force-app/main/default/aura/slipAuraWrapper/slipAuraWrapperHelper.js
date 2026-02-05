({
    refreshOmniScript: function(component) {
        // This triggers a full page refresh, which reloads the OmniScript
        $A.get("e.force:refreshView").fire();
    },

    // Invokes the subscribe method on the empApi component
    subscribe : function(component, event, helper) {
        // Get the empApi component
        const empApi = component.find('empApi');
        // Get the channel from the input box
        const channel = "/event/Toast_Notification__e"
        // Replay option to get new events
        const replayId = -1;

        // Subscribe to an event
        empApi.subscribe(channel, replayId, $A.getCallback(eventReceived => {
            // Process event (this is called each time we receive an event)
            console.log('desde event received: ',eventReceived.data.payload.recordId__c,eventReceived.data.payload.parentRecordId__c,component.get("v.recordId"),eventReceived.data.payload.userId__c,component.get('v.userId'));

            if((eventReceived.data.payload.recordId__c == component.get("v.recordId") || eventReceived.data.payload.parentRecordId__c == component.get("v.recordId")) && eventReceived.data.payload.userId__c.substring(0,15) == component.get('v.userId').substring(0,15)){
                $A.get("e.force:refreshView").fire();
                component.set("v.showOmni", false);
                window.setTimeout(() => {
                    component.set("v.showOmni", true);
                }, 10);
            }
            console.log('Received event ', JSON.stringify(eventReceived.data.payload));
        }))
        .then(subscription => {
            // Subscription response received.
            // We haven't received an event yet.
            console.log('Subscription request sent to: ', subscription.channel);
            // Save subscription to unsubscribe later
            component.set('v.subscription', subscription);
        });
    },

    // Invokes the unsubscribe method on the empApi component
    unsubscribe : function(component, event, helper) {
        // Get the empApi component
        const empApi = component.find('empApi');
        // Get the subscription that we saved when subscribing
        const subscription = component.get('v.subscription');

        // Unsubscribe from event
        empApi.unsubscribe(subscription, $A.getCallback(unsubscribed => {
          // Confirm that we have unsubscribed from the event channel
          console.log('Unsubscribed from channel '+ unsubscribed.subscription);
          component.set('v.subscription', null);
        }));
    },
})