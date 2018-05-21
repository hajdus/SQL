--Update all post their revisions


UPDATE wp_posts t, (SELECT ID, Max(post_modified), post_title, post_content, post_name, post_parent 
FROM wp_posts WHERE post_name LIKE "%revision%" GROUP BY Post_parent) t1
   SET t.post_content = t1.post_content
 WHERE t.ID = t1.post_parent
  
