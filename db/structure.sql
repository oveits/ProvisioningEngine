CREATE TABLE "customers" ("id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, "name" varchar(255), "created_at" datetime, "updated_at" datetime, "status" varchar(255), "target_id" integer);
CREATE TABLE "delayed_jobs" ("id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, "priority" integer DEFAULT 0 NOT NULL, "attempts" integer DEFAULT 0 NOT NULL, "handler" text NOT NULL, "last_error" text, "run_at" datetime, "locked_at" datetime, "failed_at" datetime, "locked_by" varchar(255), "queue" varchar(255), "created_at" datetime, "updated_at" datetime);
CREATE TABLE "provisionings" ("id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, "action" varchar(255), "created_at" datetime, "updated_at" datetime, "status" varchar(255), "customer_id" integer, "site_id" integer, "delayedjob" reference, "attempts" integer, "user_id" integer);
CREATE TABLE "schema_migrations" ("version" varchar(255) NOT NULL);
CREATE TABLE "sites" ("id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, "name" varchar(255), "customer_id" integer, "created_at" datetime, "updated_at" datetime, "status" varchar(255), "sitecode" varchar(255), "countrycode" varchar(255), "areacode" varchar(255), "localofficecode" varchar(255), "extensionlength" varchar(255), "mainextension" varchar(255), "gatewayIP" varchar(255));
CREATE TABLE "targets" ("id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, "name" varchar(255), "configuration" text, "created_at" datetime, "updated_at" datetime);
CREATE TABLE "users" ("id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, "name" varchar(255), "site_id" integer, "extension" varchar(255), "givenname" varchar(255), "familyname" varchar(255), "email" varchar(255), "created_at" datetime, "updated_at" datetime, "status" varchar(255));
CREATE INDEX "delayed_jobs_priority" ON "delayed_jobs" ("priority", "run_at");
CREATE INDEX "index_customers_on_target_id" ON "customers" ("target_id");
CREATE INDEX "index_provisionings_on_customer_id" ON "provisionings" ("customer_id");
CREATE INDEX "index_provisionings_on_site_id" ON "provisionings" ("site_id");
CREATE INDEX "index_provisionings_on_user_id" ON "provisionings" ("user_id");
CREATE INDEX "index_sites_on_customer_id" ON "sites" ("customer_id");
CREATE INDEX "index_users_on_site_id" ON "users" ("site_id");
CREATE UNIQUE INDEX "unique_schema_migrations" ON "schema_migrations" ("version");
INSERT INTO schema_migrations (version) VALUES ('20140721173546');

INSERT INTO schema_migrations (version) VALUES ('20140721173737');

INSERT INTO schema_migrations (version) VALUES ('20140728151630');

INSERT INTO schema_migrations (version) VALUES ('20140729164634');

INSERT INTO schema_migrations (version) VALUES ('20140802004343');

INSERT INTO schema_migrations (version) VALUES ('20140802005009');

INSERT INTO schema_migrations (version) VALUES ('20140802005115');

INSERT INTO schema_migrations (version) VALUES ('20140805122521');

INSERT INTO schema_migrations (version) VALUES ('20140805131901');

INSERT INTO schema_migrations (version) VALUES ('20140805155557');

INSERT INTO schema_migrations (version) VALUES ('20140805160904');

INSERT INTO schema_migrations (version) VALUES ('20140805161451');

INSERT INTO schema_migrations (version) VALUES ('20140805161609');

INSERT INTO schema_migrations (version) VALUES ('20140805161637');

INSERT INTO schema_migrations (version) VALUES ('20140805161710');

INSERT INTO schema_migrations (version) VALUES ('20140805161753');

INSERT INTO schema_migrations (version) VALUES ('20140805161838');

INSERT INTO schema_migrations (version) VALUES ('20140805164905');

INSERT INTO schema_migrations (version) VALUES ('20140808124522');

INSERT INTO schema_migrations (version) VALUES ('20140809094111');

INSERT INTO schema_migrations (version) VALUES ('20140809110212');

INSERT INTO schema_migrations (version) VALUES ('20140817172734');

INSERT INTO schema_migrations (version) VALUES ('20140820060722');

INSERT INTO schema_migrations (version) VALUES ('20140820061331');

INSERT INTO schema_migrations (version) VALUES ('20140821220517');

INSERT INTO schema_migrations (version) VALUES ('20140821221257');

