# docker-seafile-pro

A Docker Image to host Seafile Pro Server.

## How to use

1. Update `./src/Dockerfile` with your Seafile pro user ID. (This is found in your URL when you sign into the download portal)
2. Build the image using `docker build -t seafile-pro:latest ./src`
3. Enjoy!

## Misc Info

### Volumes

- `/shared/seafile` - Stores all data dirs for Seafile
- `/var/lib/mysql` - Stores MySQL data

### Environment Variables

- `SEAFILE_ADMIN_EMAIL` - Email for the admin user (Only needed on the first run)

  - Example: `SEAFILE_ADMIN_EMAIL=bob@joe.com`

- `SEAFILE_ADMIN_PASSWORD` - Password for the admin user (Only needed on the first run)

  - Example: `SEAFILE_ADMIN_PASSWORD=P@sSW0Rd!`

- `SEAFILE_DOMAIN` - The domain you are using to host Seafile

  - Example: `SEAFILE_DOMAIN=seafile.domain.com`

- `IS_HTTPS` - Used to enable HTTPS. Set to anything to enable.

  - Example: `IS_HTTPS=true`

- `CI_TEST` - Used when running CI tests on the images to skip the mount check

  - Example: `CI_TEST=true`

### CI Testing

This image includes basic tests to verify that an image will work correctly. To run tests, you will need to set `CI_TEST` and then call the CI test script in the image.

- Example: `docker run -it -e CI_TEST=true seafile-pro:latest /sbin/my_init -- /scripts/ci_test.sh`

## To Do

1. Add more checks to CI logic
2. Investigate Garbage Collection
