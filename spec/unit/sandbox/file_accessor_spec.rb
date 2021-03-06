require File.expand_path('../../../spec_helper', __FILE__)

module Pod
  describe FileAccessor = Sandbox::FileAccessor do

    before do
      @root = fixture('banana-lib')
      @path_list = Sandbox::PathList.new(@root)
      @spec = fixture_spec('banana-lib/BananaLib.podspec')
      @spec_consumer = @spec.consumer(:ios)
      @accessor = FileAccessor.new(@path_list, @spec_consumer)
    end

    describe "In general" do

      it "raises if the consumer is nil" do
        e = lambda { FileAccessor.new(@path_list, nil) }.should.raise Informative
        e.message.should.match /without a specification consumer/
      end

      it "raises if the root does not exits" do
        root = temporary_directory + 'missing_folder'
        path_list = Sandbox::PathList.new(root)
        file_accessor = FileAccessor.new(path_list, @spec_consumer)
        e = lambda { file_accessor.source_files }.should.raise Informative
        e.message.should.match /non existent folder/
      end

      it "returns the root" do
        @accessor.root.should == @path_list.root
      end

      it "returns the specification" do
        @accessor.spec.should == @spec
      end

      it "returns the platform for which the spec is being consumed" do
        @accessor.platform_name.should == :ios
      end

    end

    #-------------------------------------------------------------------------#

    describe "Returning files" do

      it "returns the source files" do
        @accessor.source_files.sort.should == [
          @root + "Classes/Banana.h",
          @root + "Classes/Banana.m",
          @root + "Classes/BananaPrivate.h"
        ]
      end

      it "returns the header files" do
        @accessor.headers.sort.should == [
          @root + "Classes/Banana.h",
          @root + "Classes/BananaPrivate.h"
        ]
      end

      it "returns the public headers" do
        @accessor.public_headers.sort.should == [
          @root + "Classes/Banana.h"
        ]
      end

      it "returns all the headers if no public headers are defined" do
        @spec_consumer.stubs(:public_header_files).returns([])
        @accessor.public_headers.sort.should == [
          @root + "Classes/Banana.h",
          @root + "Classes/BananaPrivate.h"
        ]
      end

      it "returns the resources" do
        @accessor.resources.sort.should == [
          @root + "Resources/logo-sidebar.png",
          @root + "Resources/sub_dir",
        ]
      end

      it "includes folders in the resources" do
        @accessor.resources.should.include?(@root + "Resources/sub_dir")
      end

      it "returns the preserve paths" do
        @accessor.preserve_paths.sort.should == [
          @root + "preserve_me.txt"
        ]
      end

      it "includes folders in the preserve paths" do
        @spec_consumer.stubs(:preserve_paths).returns(["Resources"])
        @accessor.preserve_paths.should.include?(@root + "Resources")
      end

      it "returns the prefix header of the specification" do
        @accessor.prefix_header.should == @root + 'Classes/BananaLib.pch'
      end

      it "returns the README file of the specification" do
        @accessor.readme.should == @root + 'README'
      end

      it "returns the license file of the specification" do
        @accessor.license.should == @root + 'LICENSE'
      end

      #--------------------------------------#

      it "respects the exclude files" do
        @spec_consumer.stubs(:exclude_files).returns(["Classes/BananaPrivate.h"])
        @accessor.source_files.sort.should == [
          @root + "Classes/Banana.h",
          @root + "Classes/Banana.m",
        ]
      end

    end

    #-------------------------------------------------------------------------#

    describe "Private helpers" do

      describe "#paths_for_attribute" do

        it "takes into account dir patterns and excluded files" do
          file_patterns = ["Classes/*.{h,m}", "Vendor"]
          options = {
            :exclude_patterns => ["Classes/**/osx/**/*", "Resources/**/osx/**/*"],
            :dir_pattern => "*.{h,hpp,hh,m,mm,c,cpp}",
            :include_dirs => false,
          }
          @spec.exclude_files = options[:exclude_patterns]
          @accessor.expects(:expanded_paths).with(file_patterns, options)
          @accessor.send(:paths_for_attribute, :source_files)
        end

      end

      describe "#expanded_paths" do

        it "can handle Rake FileLists" do
          @spec_consumer.stubs(:source_files).returns([FileList['Classes/Banana.*']])
          @accessor.source_files.sort.should == [
            @root + "Classes/Banana.h",
            @root + "Classes/Banana.m",
          ]
        end

      end

    end

    #-------------------------------------------------------------------------#

  end
end
