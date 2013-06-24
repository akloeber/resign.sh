resign.sh
=========

Script to resign an IPA package for iOS with a new certificate and provisioning profile.

This can be used by customers who do not want to give away their distribution certificate and mobile provisioning profile to the development provider for security reasons. With this script a presigned package (e.g signed with a developer certificate and bundled with a development profile) the build package can be easily resigned with the distribution certificate and distribution provisioning profile by the customer.
