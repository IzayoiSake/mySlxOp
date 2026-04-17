function trace(opts)

    arguments
        opts.direction (1,:) {mustBeMember(opts.direction,["src", "dst", "source", "destination"])} = "src";
        opts.block = '';
        opts.porttype (1,:) {mustBeMember(opts.porttype,["i","o","inport","outport"])}
        opts.sigidx (1,:) = ':'
        opts.verbose (1,1) logical = true
    end




end