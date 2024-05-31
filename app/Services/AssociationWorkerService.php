<?php

namespace App\Services;


class AssociationWorkerService
{
    private $config;
    private $client;
    private $rdb;
    private $store;
    private $apclient;

    public function __construct($config, $client, $rdb, $store, $apclient)
    {
        $this->config = $config;
        $this->client = $client;
        $this->rdb = $rdb;
        $this->store = $store;
        $this->apclient = $apclient;
    }

    public function startAssociationWorker()
    {
        $ctx = []; // context equivalent in PHP
        $notificationStream = world\UserNotifyStream . "@" . $this->config->ProxyCCID;
        $timeline = $this->client->getTimeline($ctx, $this->config->FQDN, $notificationStream);
        if (!$timeline) {
            error_log("error: failed to get timeline");
            return;
        }

        $normalized = $timeline->ID . "@" . $this->config->FQDN;
        $pubsub = $this->rdb->subscribe($ctx);
        $pubsub->subscribe($ctx, $normalized);

        while (true) {
            $pubsubMsg = $pubsub->receiveMessage($ctx);
            if (!$pubsubMsg) {
                error_log("error while receiving message");
                continue;
            }

            $streamEvent = json_decode($pubsubMsg->Payload);
            if (!$streamEvent) {
                error_log("error while unmarshalling stream event");
                continue;
            }

            $document = json_decode($streamEvent->Document);
            if (!$document) {
                error_log("error while unmarshalling document");
                continue;
            }

            $str = json_encode($streamEvent->Resource);
            if (!$str) {
                error_log("failed to marshal resource");
                continue;
            }
            $association = json_decode($str);
            if (!$association) {
                error_log("failed to unmarshal association");
                continue;
            }

            switch ($document->Type) {
                case "association":
                    if ($association->Target[0] != 'm') { // assert association target is message
                        error_log("target is not message: " . $association->Target);
                        continue;
                    }

                    $assauthor = $this->store->getEntityByCCID($ctx, $association->Author);
                    if (!$assauthor) {
                        error_log("get entity by ccid failed");
                        continue;
                    }

                    $target = $this->client->getMessage($ctx, $this->config->FQDN, $association->Target);
                    if (!$target) {
                        error_log("error: failed to get message");
                        continue;
                    }

                    $messageDoc = json_decode($target->Document);
                    if (!$messageDoc) {
                        error_log("error: failed to unmarshal message document");
                        continue;
                    }

                    if (!isset($messageDoc->Meta) || !is_array($messageDoc->Meta)) {
                        error_log("target Message is not activitypub message");
                        continue;
                    }

                    $ref = $messageDoc->Meta['apObjectRef'] ?? null;
                    if (!$ref) {
                        error_log("target Message is not activitypub message");
                        continue;
                    }

                    $inbox = $messageDoc->Meta['apPublisherInbox'] ?? null;
                    if (!$inbox) {
                        error_log("target Message is not activitypub message");
                        continue;
                    }

                    $undo = [
                        "Context" => "https://www.w3.org/ns/activitystreams",
                        "Type" => "Undo",
                        "Actor" => "https://" . $this->config->FQDN . "/ap/acct/" . $entity->ID,
                        "ID" => "https://" . $this->config->FQDN . "/ap/likes/" . $association->Target . "/undo",
                        "Object" => [
                            "Context" => "https://www.w3.org/ns/activitystreams",
                            "Type" => "Like",
                            "ID" => "https://" . $this->config->FQDN . "/ap/likes/" . $association->Target,
                            "Actor" => "https://" . $this->config->FQDN . "/ap/acct/" . $entity->ID,
                            "Object" => $ref,
                        ],
                    ];

                    $result = $this->apclient->postToInbox($ctx, $inbox, $undo, $entity);
                    if (!$result) {
                        error_log("error: failed to post to inbox");
                        continue;
                    }
                    break;
                default:
                    error_log("unknown document type: " . $document->Type);
                    break;
            }
        }
    }
}
