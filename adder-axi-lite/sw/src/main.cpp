#include <iostream>
#include <fstream>
#include <cstdint>
#include <fcntl.h>
#include <sys/mman.h>
#include <unistd.h>

const uint32_t ADDR_A_OFFSET = 0x00;
const uint32_t ADDR_B_OFFSET = 0x04;
const uint32_t ADDR_C_OFFSET = 0x08;

uint32_t parse_arg(const char *arg)
{
    char *end;
    const uint32_t value = strtol(arg, &end, 10);

    if (*end != '\0')
    {
        throw std::invalid_argument("Invalid argument: " + std::string(arg));
    }

    return value;
}

int main(int argc, char *argv[])
{
    if (argc != 4)
    {
        std::cerr << "Usage: " << argv[0] << " <uio_device> <value_a> <value_b>\n";
        std::cerr << "Example: " << argv[0] << " /dev/uio0 5 3\n";
        return 1;
    }

    const uint32_t uio_device_idx = parse_arg(argv[1]);
    const uint32_t a = parse_arg(argv[2]);
    const uint32_t b = parse_arg(argv[3]);

    const std::string uio_device = "/dev/uio" + std::to_string(uio_device_idx);

    int fd = open(uio_device.c_str(), O_RDWR);
    if (fd < 0)
    {
        throw std::runtime_error(std::string("Failed to open UIO device: ") + uio_device);
    }

    const std::string uio_size_path = "/sys/class/uio/uio" + std::to_string(uio_device_idx) + "/maps/map0/size";
    std::ifstream uio_size_file(uio_size_path);
    if (!uio_size_file.is_open())
    {
        throw std::runtime_error("Failed to open UIO size file: " + uio_size_path);
    }

    uint32_t map_size = 0;
    std::string size_str;
    if (std::getline(uio_size_file, size_str))
    {
        map_size = static_cast<uint32_t>(std::stoul(size_str, nullptr, 16));
    }
    else
    {
        throw std::runtime_error("Failed to read UIO size from: " + uio_size_path);
    }

    std::cout << "size of UIO Memory: 0x" << std::hex << map_size << std::dec << "\n";

    void *mapped_memory = mmap(nullptr, map_size, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
    if (mapped_memory == MAP_FAILED)
    {
        close(fd);
        throw std::runtime_error("Failed to mmap UIO device memory");
    }

    // Cast to volatile pointer to prevent compiler optimizations
    volatile uint32_t *mem = static_cast<volatile uint32_t *>(mapped_memory);

    std::cout << "Writing " << a << " to register at offset 0x" << std::hex << ADDR_A_OFFSET
              << " and " << std::dec << b << " to register at offset 0x" << std::hex << ADDR_B_OFFSET << std::dec << "\n";

    mem[ADDR_A_OFFSET / sizeof(uint32_t)] = a;
    mem[ADDR_B_OFFSET / sizeof(uint32_t)] = b;

    std::cout << "Wrote " << a << " to register A\n";
    std::cout << "Wrote " << b << " to register B\n";

    uint32_t c = mem[ADDR_C_OFFSET / sizeof(uint32_t)];

    std::cout << "Read from register C\n";
    std::cout << "Computed result: " << a << " + " << b << " = " << c << "\n";

    // Cleanup
    munmap(mapped_memory, map_size);
    close(fd);

    return 0;
}