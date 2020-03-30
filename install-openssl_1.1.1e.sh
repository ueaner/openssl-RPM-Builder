#!/bin/bash

# Падаем сразу, если возникли какие-то ошибки
set -e
# Выводим, то , что делаем
set -v
mkdir ~/openssl && cd ~/openssl
yum -y install \
    curl \
    which \
    make \
    gcc \
    perl \
    perl-WWW-Curl \
    rpm-build

yum -y remove openssl

# Get openssl tarball
curl -O --silent https://www.openssl.org/source/openssl-1.1.1e.tar.gz

# SPEC file
cat << 'EOF' > ~/openssl/openssl.spec
Summary: OpenSSL 1.1.1e for Centos
Name: openssl
Version: %{?version}%{!?version:1.1.1e}
Release: 1%{?dist}
Obsoletes: %{name} <= %{version}
Provides: %{name} = %{version}
URL: https://www.openssl.org/
License: GPLv2+

Source: https://www.openssl.org/source/%{name}-%{version}.tar.gz

BuildRequires: make gcc perl perl-WWW-Curl
BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root
%global openssldir /usr/openssl

%description
https://github.com/philyuchkoff/openssl-1.1.1c-RPM-Builder
OpenSSL RPM for version 1.1.1e on Centos

%package devel
Summary: Development files for programs which will use the openssl library
Group: Development/Libraries
Requires: %{name} = %{version}-%{release}

%description devel
OpenSSL RPM for version 1.1.1e on Centos (development package)

%prep
%setup -q

%build
./config --prefix=%{openssldir} --openssldir=%{openssldir}
make

%install
[ "%{buildroot}" != "/" ] && %{__rm} -rf %{buildroot}
%make_install

mkdir -p %{buildroot}%{_bindir}
mkdir -p %{buildroot}%{_libdir}
ln -sf %{openssldir}/lib/libssl.so.1.1 %{buildroot}%{_libdir}
ln -sf %{openssldir}/lib/libcrypto.so.1.1 %{buildroot}%{_libdir}
ln -sf %{openssldir}/bin/openssl %{buildroot}%{_bindir}

%clean
[ "%{buildroot}" != "/" ] && %{__rm} -rf %{buildroot}

%files
%{openssldir}
%defattr(-,root,root)
/usr/bin/openssl
/usr/lib64/libcrypto.so.1.1
/usr/lib64/libssl.so.1.1

%files devel
%{openssldir}/include/*
%defattr(-,root,root)

%post -p /sbin/ldconfig

%postun -p /sbin/ldconfig
EOF


mkdir -p /root/rpmbuild/{BUILD,RPMS,SOURCES,SPECS,SRPMS}
cp ~/openssl/openssl.spec /root/rpmbuild/SPECS/openssl.spec

mv openssl-1.1.1e.tar.gz /root/rpmbuild/SOURCES
cd /root/rpmbuild/SPECS && \
    rpmbuild \
    -D "version 1.1.1e" \
    -ba openssl.spec


# Try to install:  rpm -ivvh /root/rpmbuild/RPMS/x86_64/openssl-1.1.1e-1.el7.centos.x86_64.rpm
# I need --nodeps ??? Something is wrong

# Verify install:  rpm -qa openssl


#rpmbuild \
#    -D "dist ${dist}" \
#    -D "version ${buildver}" \
#    -D "release ${releasever}" \
#    -D "_topdir /rpmbuild" \
#    -ba rpm/pgbouncer.spec