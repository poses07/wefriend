<?php
require 'api/config/Database.php';
$db = (new Database())->getConnection();
$db->exec("
CREATE TABLE IF NOT EXISTS `story_views` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `story_id` int(11) NOT NULL,
  `viewer_id` int(11) NOT NULL,
  `viewed_at` timestamp DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_view` (`story_id`, `viewer_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

ALTER TABLE `stories` ADD COLUMN IF NOT EXISTS `views_count` int(11) DEFAULT 0;
");
echo 'Done.';
?>