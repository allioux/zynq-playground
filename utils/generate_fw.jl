using ArgParse

function generate_fw(sdt_path::String, fw_path::String, xsa_file_path::String, bin_file_path::String)
    mkpath(sdt_path)
    mkpath(fw_path)

    cmd_prefix = ""
    if Sys.iswindows()
        cmd_prefix = `powershell -Command`
    end

    #run(`sdtgen -xsa $xsa_file_path -dir $sdt_path -board_dts zynqmp-smk-k26-reva -zocl enable -trace enable -debug enable`)
    run(`lopper --enhanced -O $fw_path -f $sdt_path/system-top.dts -- xlnx_overlay_dt cortexa53-zynqmp full`)
    run(`dtc -I dts -O dtb -o $fw_path/pl.dtbo $fw_path/pl.dtsi`)

    shell_file = """{
        "shell_type": "XRT_FLAT",
        "num_slots": "1"
    }"""

    open("$fw_path/shell.json", "w") do f
        write(f, shell_file)
    end

    cp("$bin_file_path", "$fw_path/$(basename(bin_file_path))", force=true)
end

function main()
    parser = ArgParseSettings(
        description="Generate firmware device tree overlay."
    )
    @add_arg_table parser begin
        "--xsa"
            help = "Path to the XSA file."
            required = true
        "--bin"
            help = "Directory for BIN file."
            required = true
        "--sdt"
            help = "Directory for SDT files."
            required = true
        "--fw"
            help = "Output directory for firmware."
            required = true
    end

    args = parse_args(parser)

    generate_fw(args["sdt"], args["fw"], args["xsa"], args["bin"])
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
