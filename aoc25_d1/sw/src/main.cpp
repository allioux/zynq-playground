#include <iostream>
#include <fstream>
#include <cstdint>
#include <cstring>
#include <fcntl.h>
#include <sys/mman.h>
#include <unistd.h>
#include <chrono>
#include <thread>
#include <vector>

// AXI Lite register offsets for /dev/uio4 (control registers)
const uint32_t REG_START_OFFSET = 0x00;
const uint32_t REG_SIZE_OFFSET = 0x04;
const uint32_t REG_DONE_OFFSET = 0x08;
const uint32_t REG_PART1_OFFSET = 0x0C;
const uint32_t REG_PART2_OFFSET = 0x10;

// Default UIO device indices
const uint32_t DEFAULT_CTRL_IDX = 4; // /dev/uio4 for control registers
const uint32_t DEFAULT_BRAM_IDX = 5; // /dev/uio5 for BRAM data

int32_t parse_arg(const char *arg)
{
    char *end;
    const long value = strtol(arg, &end, 10);

    if (*end != '\0')
    {
        throw std::invalid_argument("Invalid argument: " + std::string(arg));
    }

    return static_cast<int32_t>(value);
}

uint32_t get_uio_map_size(uint32_t uio_idx)
{
    const std::string uio_size_path = "/sys/class/uio/uio" + std::to_string(uio_idx) + "/maps/map0/size";
    std::ifstream uio_size_file(uio_size_path);
    if (!uio_size_file.is_open())
    {
        throw std::runtime_error("Failed to open UIO size file: " + uio_size_path);
    }

    std::string size_str;
    if (std::getline(uio_size_file, size_str))
    {
        return static_cast<uint32_t>(std::stoul(size_str, nullptr, 16));
    }
    else
    {
        throw std::runtime_error("Failed to read UIO size from: " + uio_size_path);
    }
}

struct ComputationResult
{
    int64_t duration;
    int32_t part1;
    int32_t part2;
};

ComputationResult perform_computation(volatile int32_t *ctrl_mem, uint32_t array_size)
{
    // Trigger computation by setting start register
    const auto computation_start_time = std::chrono::high_resolution_clock::now();
    ctrl_mem[REG_START_OFFSET / sizeof(int32_t)] = 1;
    ctrl_mem[REG_START_OFFSET / sizeof(int32_t)] = 0;

    // Poll done register until computation completes
    uint32_t done = 0;
    while (done == 0)
    {
        done = ctrl_mem[REG_DONE_OFFSET / sizeof(int32_t)] & 0x1;
    }

    const auto computation_end_time = std::chrono::high_resolution_clock::now();
    const auto computation_duration = std::chrono::duration_cast<std::chrono::nanoseconds>(computation_end_time - computation_start_time);

    int32_t part1 = ctrl_mem[REG_PART1_OFFSET / sizeof(int32_t)];
    int32_t part2 = ctrl_mem[REG_PART2_OFFSET / sizeof(int32_t)];
    return {computation_duration.count(), part1, part2};
}

int main(int argc, char *argv[])
{
    if (argc < 2)
    {
        std::cerr << "Usage: " << argv[0] << " <input_file>\n";
        return 1;
    }

    std::vector<int32_t> input_array;

    std::ifstream input_file(argv[1]);
    if (input_file.is_open())
    {
        std::string line;
        while (std::getline(input_file, line))
        {
            if (line.empty())
                continue;

            char direction = line[0];
            int32_t value = std::stoi(line.substr(1));

            if (direction == 'R')
            {
                input_array.push_back(value);
            }
            else if (direction == 'L')
            {
                input_array.push_back(-value);
            }
            else
            {
                throw std::invalid_argument("Invalid direction in file: " + line);
            }
        }
        input_file.close();
    }
    else
    {
        throw std::runtime_error("Failed to open input file: " + std::string(argv[1]));
    }

    const uint32_t array_size = input_array.size();

    const std::string bram_device = "/dev/uio" + std::to_string(DEFAULT_BRAM_IDX);
    std::cerr << "Opening BRAM device: " << bram_device << std::endl;
    int bram_fd = open(bram_device.c_str(), O_RDWR | O_SYNC);
    if (bram_fd < 0)
    {
        throw std::runtime_error(std::string("Failed to open BRAM device: ") + bram_device);
    }

    uint32_t bram_size = get_uio_map_size(DEFAULT_BRAM_IDX);
    std::cerr << "BRAM size: " << bram_size << " bytes" << std::endl;
    std::cerr << "Array size to copy: " << (array_size * sizeof(int32_t)) << " bytes" << std::endl;

    if (array_size * sizeof(int32_t) > bram_size)
    {
        close(bram_fd);
        throw std::runtime_error("Input array exceeds BRAM size");
    }

    void *bram_mapped = mmap(nullptr, bram_size, PROT_READ | PROT_WRITE, MAP_SHARED, bram_fd, 0);
    if (bram_mapped == MAP_FAILED)
    {
        close(bram_fd);
        throw std::runtime_error("Failed to mmap BRAM device");
    }
    std::cerr << "BRAM mapped at: " << bram_mapped << std::endl;

    std::cerr << "Copying array to BRAM..." << std::endl;
    volatile int32_t *bram_ptr = static_cast<volatile int32_t *>(bram_mapped);
    for (uint32_t i = 0; i < array_size; ++i)
    {
        bram_ptr[i] = input_array[i];
    }
    std::cerr << "Array copied successfully" << std::endl;

    std::this_thread::sleep_for(std::chrono::milliseconds(100));

    __sync_synchronize();

    const std::string ctrl_device = "/dev/uio" + std::to_string(DEFAULT_CTRL_IDX);
    std::cerr << "Opening control device: " << ctrl_device << std::endl;
    int ctrl_fd = open(ctrl_device.c_str(), O_RDWR | O_SYNC);
    if (ctrl_fd < 0)
    {
        munmap(bram_mapped, bram_size);
        close(bram_fd);
        throw std::runtime_error(std::string("Failed to open control device: ") + ctrl_device);
    }

    uint32_t ctrl_size = get_uio_map_size(DEFAULT_CTRL_IDX);
    std::cerr << "Control register size: " << ctrl_size << " bytes" << std::endl;

    void *ctrl_mapped = mmap(nullptr, ctrl_size, PROT_READ | PROT_WRITE, MAP_SHARED, ctrl_fd, 0);
    if (ctrl_mapped == MAP_FAILED)
    {
        close(bram_fd);
        close(ctrl_fd);
        munmap(bram_mapped, bram_size);
        throw std::runtime_error("Failed to mmap control device");
    }
    std::cerr << "Control registers mapped at: " << ctrl_mapped << std::endl;

    volatile int32_t *ctrl_mem = static_cast<volatile int32_t *>(ctrl_mapped);
    std::cerr << "Setting SIZE register to: " << array_size << std::endl;
    ctrl_mem[REG_SIZE_OFFSET / sizeof(int32_t)] = array_size;

    // Run computation 1000 times
    std::vector<ComputationResult> results;
    std::cerr << "Starting 1000 computation iterations..." << std::endl;

    for (int iter = 0; iter < 1000; ++iter)
    {
        try
        {
            ComputationResult result = perform_computation(ctrl_mem, array_size);
            results.push_back(result);
        }
        catch (const std::exception &e)
        {
            std::cerr << "Error on iteration " << iter << ": " << e.what() << std::endl;
            throw;
        }
    }
    std::cerr << "All iterations completed successfully" << std::endl;

    int64_t total = 0;
    int64_t min_duration = results[0].duration;
    int64_t max_duration = results[0].duration;

    for (const auto &r : results)
    {
        total += r.duration;
        if (r.duration < min_duration)
            min_duration = r.duration;
        if (r.duration > max_duration)
            max_duration = r.duration;
    }

    double average_ns = static_cast<double>(total) / results.size();
    
    std::cout << "=== Day 1 ===\n";
    std::cout << "Part 1: " << results[0].part1 << " | Part 2: " << results[0].part2 << " | Min: " << min_duration / 1000.0 << " μs | Max: " << max_duration / 1000.0 << " μs | Avg: " << average_ns / 1000.0 << " μs\n";

    // Cleanup
    munmap(bram_mapped, bram_size);
    munmap(ctrl_mapped, ctrl_size);
    close(bram_fd);
    close(ctrl_fd);

    return 0;
}