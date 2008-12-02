Water Cooler -- AJAX chat for the enterprise
===

Requirements
---

Water Cooler requires Rails 2.1 and the following gems:

* `ruby-net-ldap`
* `ruby-openid`
* `haml`
* `RedCloth`

Installation
---

* Make sure the required gems are installed ("rake gems").
* Set up your database information in +config/database.yaml+.
* Migrate your database.
* Set up which services you want to use in +config/application.yml+.
* Start the server and go

Usage
---

Water Cooler should be fairly straightforward, but there are several main features to know about.

---
**Users and logging in**

When a user first logs in, Water Cooler looks for an existing user in the database. For LDAP users, it looks for a user with the same short username. For OpenID users, it looks for the OpenID identity in the username field of the users. If the user isn't found, it creates a new user. On the first login, Water Cooler will also give a user a nickname. For LDAP users, this is the same as the username (however a nice feature would be to check for a nickname LDAP attribute). For OpenID users, the simple registration `nickname` parameter is used.

At each login Water Cooler checks a few things. First, it sets the time zone for the user. The time zone is determined via Javascript for LDAP users and simple registration for OpenID users. It also checks to see if the user is an administrator. For LDAP users it checks the admin group defined in `application.yml`. For OpenID users it checks the list of OpenID admins in `application.yml`.

After login, the user is taken to the list of chat rooms.

**Changing nicknames**

In the page footer, there is a line of text that says "You are known as...". By clicking "change", the user can change his or her nickname. The new nickname will appear in the list of room members and before each message posted by the user. To see a user's username (i.e. LDAP username or OpenID identity), just hover over the person's name in the room member list and the tooltip will show the real name.

**Away messages**

Users can set an away message indicating that they aren't currently paying attention to the chat. Away messages are listed next to a user's nickname in the member list for each chat room.

When a user is away, all notifications are sticky and stay visible until the user returns from away.

**Away status**

The member list for a chat room shows all of the current members of the room. If a user's nickname is italicized, it means that they are either away, or currently viewing a different chat room. Non-italicized names may be a little misleading however since they may indicate simply that a user was last viewing the room before closing their browser, even if they haven't visited it in weeks.

**Evicting members**

Administrators and the owner of a room can evict any member of that room. This will boot the member from the room the next time their browser hits the room checking for new messages.

Bug reports
---

Please submit bug reports via Lighthouse at http://thadd.lighthouseapp.com/projects/20676-water-cooler/overview.

License
--

Water Cooler is released under the MIT license.
