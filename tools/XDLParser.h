//
// Copyright 2012 www.bitfury.org
//
#ifndef XDLPARSER_H_INCLUDED
#define XDLPARSER_H_INCLUDED

#include <string>
#include <map>
#include <vector>

namespace XDL {

    class Pip {
        public:
            std::string tile, wire0, dir, wire1;

            bool parse(std::string::const_iterator& b, std::string::const_iterator e);
            void format(std::string& dst) const;
    };

    class Pin {
        public:
            std::string comp;
            std::string pin;

            bool operator < (const Pin& o) const { if (comp < o.comp) return true; if (comp > o.comp) return false; if (pin < o.pin) return true; return false; }

            bool parse(std::string::const_iterator& b, std::string::const_iterator e);
            void format(std::string& dst) const;
    };

    class Net {
        public:
            Pin outpin;
            typedef std::vector<Pin> inpin_type;
            typedef std::vector<Pip> routing_type;
            inpin_type inpin;
            routing_type routing;
            std::string pwr;

            bool parse(std::string::const_iterator& b, std::string::const_iterator e);
            void format(std::string& dst) const; // Concatenate result
    };

    int parse_slice_x(const std::string &s);
    int parse_slice_y(const std::string &s);

    class Instance {
        public:
            std::string primtype;     // SLICEL/SLICEM/SLICEX/TIEOFF/IOB
            std::string place_switch; // Switch placement
            std::string place;
            std::string module_inst;     // Module instance
            std::string module;          // Module name
            std::string module_int_inst; // Instance name inside of module
            std::string cfg;          // Component configuration information

            bool parse(std::string::const_iterator& b, std::string::const_iterator e);
            void format(std::string& dst) const;
    };

    class Port {
        public:
            std::string inst; // Instance name
            std::string pin;

            bool parse(std::string::const_iterator& b, std::string::const_iterator e);
            void format(std::string& dst) const;
    };

    class Module {
        public:
            std::string refcomp;
            std::string cfg;

            typedef std::map<std::string, Port> ports_type;
            typedef std::map<std::string, Instance> insts_type;
            typedef std::map<std::string, Net> nets_type;

            ports_type ports;
            insts_type insts;
            nets_type nets;

            bool parse(std::string::const_iterator& b, std::string::const_iterator e);
            void format(std::string& dst) const;
    };

    class Design {
        public:
            std::string name;
            std::string device;
            std::string version;
            std::string cfg;

            typedef std::map<std::string, Instance> insts_type;
            typedef std::map<std::string, Net> nets_type;
            typedef std::map<std::string, Module> modules_type;

            insts_type insts;
            nets_type nets;
            modules_type modules;

            bool parse(std::string::const_iterator& b, std::string::const_iterator e);
            void format(std::string& dst) const;

            bool load(const std::string& fn);
            bool save(const std::string& fn);
    };
};

#endif // XDLPARSER_H_INCLUDED
