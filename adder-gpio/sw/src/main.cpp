#include <algorithm>
#include <bitset>
#include <filesystem>
#include <format>
#include <gpiod.hpp>
#include <iostream>
#include <cstdint>
#include <vector>

namespace fs = std::filesystem;

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
    if (argc != 6)
    {
        return 1;
    }

    const int gpiochip_a_idx = parse_arg(argv[1]);
    const int gpiochip_b_idx = parse_arg(argv[2]);
    const int gpiochip_c_idx = parse_arg(argv[3]);

    const int a = parse_arg(argv[4]);
    const int b = parse_arg(argv[5]);

    gpiod::chip chip_a = gpiod::chip("/dev/gpiochip" + std::to_string(gpiochip_a_idx));
    gpiod::chip chip_b = gpiod::chip("/dev/gpiochip" + std::to_string(gpiochip_b_idx));
    gpiod::chip chip_c = gpiod::chip("/dev/gpiochip" + std::to_string(gpiochip_c_idx));

    if (chip_a.get_info().num_lines() != 32 ||
        chip_b.get_info().num_lines() != 32 ||
        chip_c.get_info().num_lines() != 32)
    {
        throw std::runtime_error("All chips must have 32 lines");
    }

    gpiod::line::offsets line_offsets;
    for (uint32_t i = 0; i < 32; i++)
    {
        line_offsets.push_back(i);
    }

    gpiod::line_settings input_line_settings = gpiod::line_settings()
                                                   .set_direction(gpiod::line::direction::INPUT);

    gpiod::line_settings output_line_settings = gpiod::line_settings()
                                                    .set_direction(gpiod::line::direction::OUTPUT);

    std::bitset<32> a_bits(a);
    std::bitset<32> b_bits(b);

    gpiod::line::values a_values;
    gpiod::line::values b_values;
    gpiod::line::values c_values;

    for (uint32_t i = 0; i < 32; i++)
    {
        a_values.push_back(a_bits[i] ? gpiod::line::value::ACTIVE : gpiod::line::value::INACTIVE);
        b_values.push_back(b_bits[i] ? gpiod::line::value::ACTIVE : gpiod::line::value::INACTIVE);
        c_values.push_back(gpiod::line::value::INACTIVE);
    }

    std::cout << "Writing " << a << " to chip_a and " << b << " to chip_b\n";

    auto request_a = chip_a.prepare_request().add_line_settings(line_offsets, output_line_settings).set_output_values(a_values).do_request();

    std::cout << "Wrote " << a << " to chip_a\n";

    auto request_b = chip_b.prepare_request().add_line_settings(line_offsets, output_line_settings).set_output_values(b_values).do_request();

    std::cout << "Wrote " << b << " to chip_b\n";

    chip_c.prepare_request().add_line_settings(line_offsets, input_line_settings).do_request().get_values(c_values);

    std::cout << "Read from chip_c\n";

    std::bitset<32> c_bits;
    for (size_t i = 0; i < c_values.size(); i++)
    {
        c_bits[i] = (c_values[i] == gpiod::line::value::ACTIVE) ? 1 : 0;
    }

    uint32_t c = static_cast<uint32_t>(c_bits.to_ulong());

    std::cout << "Computed result: " << a << " + " << b << " = " << c << "\n";

    return 0;
}