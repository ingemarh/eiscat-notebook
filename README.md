## Step 1. Clone this Repository
Clone this repository to your Linux client using 
    `git clone https://github.com/ingemarh/eiscat-notebook.git`

## Step 2. Choose MATLAB version and defaul license
Edit Dockerfile

## Step 5. Build Image
Use the `docker build` command to build the image, using ```.``` to specify this folder. Run the command from the root directory of the cloned repository. Use a command of the form:
```
docker build -t eiscat:juma --build-arg LICENSE_SERVER=27000@MyServerName .
```
**Note**: The `LICENSE_SERVER` build argument is NOT used during the build but by supplying it here during build it gets
incorporated into the container so that MATLAB in the container knows how to acquire a license when the container is run

```
docker run -it --rm eiscat:jumaa
```
- `-it` option runs the container interactively.
- `--rm` option automatically removes the container on exit.


Edit the `Dockerfile` and uncomment the relevant lines to install the dependencies.
## Use a License File to Build Image
If you have a `license.dat` file from your license administrator, you can use this file to provide the location of the license manager for the container image.
1. Open the `license.dat` file. Copy the `SERVER` line into a new text file. 
2. Beneath it, add `USE_SERVER`. The file should now look something like this:
```
SERVER Server1 0123abcd0123 12345
USE_SERVER
```
3. Save the new text file as `network.lic` in the root directory of the cloned repository.
4. Open the `Dockerfile`, and comment the line `ENV MLM_LICENSE_FILE`
5. Uncomment the line `ADD network.lic /usr/local/MATLAB/$MATLAB_RELEASE/licenses/`
6. Run the docker build command without the `--build-arg LICENSE_SERVER=27000@MyServerName` option. Use a command of the form
```
docker build -t eiscat:juma .
```
