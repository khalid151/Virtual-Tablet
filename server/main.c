#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <linux/uinput.h>
#include <signal.h>
#include <string.h>
#include <stdint.h>
#include <poll.h>
#include <sys/socket.h>
#include <arpa/inet.h>

#define DEVICE_NAME "Virtual Graphics Tablet"
#define PORT 9000
#define MAGIC "VTAB"

// button state
#define BUTTON_UP 0
#define BUTTON_DOWN 1
// stylus state
#define STYLUS_HOVER 0
#define STYLUS_PRESS 1
#define STYLUS_BTN 2


int exit_status = EXIT_SUCCESS;
static volatile sig_atomic_t stop = 0;

struct stylus_event {
    char magic[4];
    uint16_t x;
    uint16_t y;
    uint16_t pressure: 14;
    uint8_t down: 2;
    uint8_t buttons;
} __attribute__((packed));


void signal_handler(int sig)
{
    stop = 1;
}

void send_event(int fd, int type, int code, int val)
{
    struct input_event event = {
        .type = type,
        .code = code,
        .value = val,
        .time.tv_sec = 0,
        .time.tv_usec = 0,
    };

    write(fd, &event, sizeof(event));
}

void prepare_device(int fd)
{
    // Enable device features
    ioctl(fd, UI_SET_EVBIT, EV_SYN);
    ioctl(fd, UI_SET_EVBIT, EV_KEY);

    // Stylus
    ioctl(fd, UI_SET_KEYBIT, BTN_TOOL_PEN);
    ioctl(fd, UI_SET_KEYBIT, BTN_TOUCH);
    ioctl(fd, UI_SET_KEYBIT, BTN_STYLUS);

    // Movement and pressure
    ioctl(fd, UI_SET_EVBIT, EV_ABS);
    ioctl(fd, UI_SET_ABSBIT, ABS_X);
    ioctl(fd, UI_SET_ABSBIT, ABS_Y);
    ioctl(fd, UI_SET_ABSBIT, ABS_PRESSURE);

    struct uinput_abs_setup asetup;
    struct uinput_setup usetup;

    // Set axis
    memset(&asetup, 0, sizeof(asetup));
    asetup.code = ABS_X;
    asetup.absinfo.value = 0;
    asetup.absinfo.minimum = 0;
    asetup.absinfo.maximum = UINT16_MAX;
    asetup.absinfo.fuzz = 0;
    asetup.absinfo.flat = 0;
    asetup.absinfo.resolution = 400;
    ioctl(fd, UI_ABS_SETUP, &asetup);

    memset(&asetup, 0, sizeof(asetup));
    asetup.code = ABS_Y;
    asetup.absinfo.value = 0;
    asetup.absinfo.minimum = 0;
    asetup.absinfo.maximum = UINT16_MAX;
    asetup.absinfo.fuzz = 0;
    asetup.absinfo.flat = 0;
    asetup.absinfo.resolution = 400;
    ioctl(fd, UI_ABS_SETUP, &asetup);

    memset(&asetup, 0, sizeof(asetup));
    asetup.code = ABS_PRESSURE;
    asetup.absinfo.value = 0;
    asetup.absinfo.minimum = 0;
    asetup.absinfo.maximum = 8192;
    asetup.absinfo.fuzz = 0;
    asetup.absinfo.flat = 0;
    asetup.absinfo.resolution = 0;
    ioctl(fd, UI_ABS_SETUP, &asetup);

    // Set device properties
    memset(&usetup, 0, sizeof(usetup));
    usetup.id.bustype = BUS_VIRTUAL;
    usetup.id.vendor = 0x1;
    usetup.id.product = 0x1;
    usetup.id.version = 2;
    usetup.ff_effects_max = 0;
    strcpy(usetup.name, DEVICE_NAME);

    // Actually create device
    ioctl(fd, UI_DEV_SETUP, &usetup);
    ioctl(fd, UI_DEV_CREATE);
}

int main(int argc, char *argv[])
{
    // Handle signals
    signal(SIGINT, signal_handler);
    signal(SIGTERM, signal_handler);

    // Setup device
    int dev = open("/dev/uinput", O_WRONLY | O_NONBLOCK);
    prepare_device(dev);

    // Setup TCP server
    int sockfd, connfd;
    sockfd = socket(AF_INET, SOCK_STREAM, 0);
    struct sockaddr_in addr, client_addr;
    memset(&addr, 0, sizeof(addr));
    memset(&client_addr, 0, sizeof(client_addr));
    addr.sin_family = AF_INET;
    addr.sin_addr.s_addr = htonl(INADDR_ANY); addr.sin_port = htons(PORT);
    if(bind(sockfd, (struct sockaddr *)&addr, sizeof(addr)) < 0) {
        fprintf(stderr, "Failed to bind address on port %d\n", PORT);
        exit_status = EXIT_FAILURE;
        goto OUT;
    }

    if(listen(sockfd, 0) < 0) {
        perror("Listening failed\n");
        exit_status = EXIT_FAILURE;
        goto OUT;
    }

    socklen_t len = sizeof(client_addr);

    struct pollfd fds[2] = {
        {
            .fd = sockfd,
            .events = POLLIN,
            .revents = 0,
        },
        {
            .events = POLLIN,
            .revents = 0,
        },
    };

    /*
     * Events:
     *  EV_ABS:
     *      - ABS_X
     *      - ABS_Y
     *      - ABS_PRESSURE
     *  EV_KEY:
     *      BTN_TOOL_PEN
     *  EV_SYN:
     *      SYN_REPORT
     */

    struct stylus_event event;
    nfds_t nfds = sizeof(fds)/sizeof(struct pollfd);

    // Process events
    while(!stop && poll(fds, nfds, -1) > -1) {
        if(fds[0].revents & POLLIN) {
            connfd = accept(sockfd, (struct sockaddr*)&client_addr, &len);
            fds[1].fd = connfd;
        } else if(fds[1].revents & POLLIN) {
            memset(&event, 0, sizeof(event));
            if(read(connfd, &event, sizeof(event)) > 0) {
                if(!memcmp(event.magic, MAGIC, strlen(MAGIC))) {
                    send_event(dev, EV_ABS, ABS_X, event.x);
                    send_event(dev, EV_ABS, ABS_Y, event.y);
                    send_event(dev, EV_ABS, ABS_PRESSURE, event.pressure);

                    switch (event.buttons) {
                        case STYLUS_HOVER:
                            send_event(dev, EV_SYN, SYN_REPORT, 1);
                            break;
                        case STYLUS_PRESS:
                            send_event(dev, EV_KEY, BTN_TOOL_PEN, event.down);
                            break;
                        default:
                            send_event(dev, EV_SYN, SYN_REPORT, 1);
                    }
                }
            }
        }
    }

OUT:
    ioctl(dev, UI_DEV_DESTROY);
    close(dev);
    close(sockfd);

    return exit_status;
}
