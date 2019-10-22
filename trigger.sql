USE [lansweeperdb]
GO
/****** Object:  Trigger [dbo].[addingTicket]    Script Date: 8/16/2019 9:46:16 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Eric Bash
-- Create date: 7/3/2019
-- Updates 7/18/219
-- Description:	Will fill in needed info when a ticket has been added to the table
-- =============================================
ALTER TRIGGER [dbo].[addingTicket] 
   ON  [dbo].[htblticket] 
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;


	/* Declaring varibles for use throughout program */
	-- ===================================================================================================
	DECLARE
	/* These are variables needed for future queries to get infomation */
	@ticket_id INT,						-- ID number given to a ticket
	@user_id INT,						-- ID number given to a user when a ticket is made. ID is not the same as user asset ID!
	@login_name nvarchar(150),			-- Name used by user to login to computer and VDI
	@physical_computer_asset_id INT,	-- ID number for asset for physical computer
	@virtual_computer_asset_id INT,		-- ID number for asset for VDI
	@source_id INT,						-- ID number to tell what the source for the ticket is

	/* These variables are used to store infomation about a user to be filled into the ticket custom fields */
	@office nvarchar(150),				-- The office that the user works
	@physical_computer nvarchar(150),
	@virtual_computer nvarchar(150),
	@host nvarchar(150),
	@video_card nvarchar(500),
	@monitor1 nvarchar(150),
	@monitor2 nvarchar(150),
	@monitor_serial nvarchar(150);








	/* These calls set variables for future uses in the code */
	-- ===================================================================================================
	-- Gets ticket id from inserted ticket
	SELECT @ticket_id = ticketid 
	FROM INSERTED

/*	UPDATE htblticketcustomfield
	SET data = @ticket_id
	WHERE fieldid = 65
	AND ticketid = 312
*/



	-- Gets user concerning id from inserted ticket
	SELECT @user_id = fromuserid 
	FROM INSERTED





	SELECT @source_id = sourceid
	FROM INSERTED





	-- Uses the user id to get the username
	SELECT @login_name = username 
	FROM htblusers 
	WHERE userid = @user_id

	 



	 -- Gets the physical compter asset using the loging name and uses keyword "PC" to throw out VDIs. Ordered to get latest computer
	SELECT @physical_computer_asset_id = AssetID 
	FROM tblAssets 
	WHERE Username = @login_name 
	AND AssetName LIKE '%PC%' 
	ORDER BY Lastseen ASC





	-- Gets the physical compter asset using the loging name and uses the login name as a keyword to throw out physical compters. Ordered to get latest computer
	SELECT @virtual_computer_asset_id = AssetID 
	FROM tblAssets 
	WHERE Username = @login_name 
	AND AssetName LIKE '%' + @login_name + '%' 
	ORDER BY Lastseen ASC
	




	/* These queries get the infomation needed from a user using info gained above */
	-- Gets office user works at with login name
	SELECT @office = Office 
	FROM tblADusers 
	WHERE Username = @login_name
	




	-- This gets the computer name using the asset id
	SELECT @physical_computer = AssetName 
	FROM tblAssets 
	WHERE AssetID = @physical_computer_asset_id
	




	-- This gets the VDI name using the asset id
	SELECT @virtual_computer = AssetName 
	FROM tblAssets 
	WHERE AssetID = @virtual_computer_asset_id
	 




	-- Will get host id with VDI name. THIS ID IS NOT THE IP. THE IP WILL BE ASSIGNED BELOW
	SELECT @host = SUBSTRING(Host,charindex('-',Host)+1,LEN(Host))
	FROM web50repvCenterVmwareGuestNetworks 
	WHERE AssetID = @virtual_computer_asset_id
	




	-- This will get the video card name with asset id
	SELECT @video_card = Caption 
	FROM tblDisplayConfiguration 
	WHERE AssetID = @virtual_computer_asset_id
	




	 -- This will get the latest used monitor from user that is a DELL or HP.
	SELECT @monitor1 =  MonitorModel 
	FROM tblMonitor 
	WHERE AssetID = @physical_computer_asset_id 
	AND (MonitorModel LIKE 'HP%' 
	OR MonitorModel LIKE 'DELL%') 
	ORDER BY LastChanged ASC
	




	-- This gets the serial number of the monitor above
	SELECT @monitor_serial =  SerialNumber 
	FROM tblMonitor 
	WHERE AssetID = @physical_computer_asset_id 
	ORDER BY LastChanged ASC
	




	-- This will get the second most recently used monitor from the user
	-- This uses a nested query to removew the most recent monitor from the returned table using the serial number
	SELECT @monitor2 =  MonitorModel 
	FROM tblMonitor
	WHERE AssetID = @physical_computer_asset_id 
	AND (MonitorModel LIKE 'HP%' 
	OR MonitorModel LIKE 'DELL%') 
	AND SerialNumber <> @monitor_serial

	 	




	/* These are assigning the infomation gained above to the correct custom field column 
		need to change what to do based on what the ticket source was.*/
	-- ===================================================================================================
	

	if @source_id = 4 OR @source_id = 1
	BEGIN
		UPDATE htblticketcustomfield
		SET data = @login_name
		WHERE fieldid = 65
		AND ticketid = @ticket_id
		AND data = '';
			




		UPDATE htblticketcustomfield
		SET data = @physical_computer 
		WHERE fieldid = 68
		AND ticketid = @ticket_id
		AND data = '';





		UPDATE htblticketcustomfield
		SET data = @office 
		WHERE fieldid = 75 
		AND ticketid = @ticket_id
		AND data = '';
		




		UPDATE htblticketcustomfield
		SET data = @virtual_computer 
		WHERE fieldid = 61 
		AND ticketid = @ticket_id
		AND data = '';
	




		UPDATE htblticketcustomfield
		SET data = @host
		WHERE fieldid = 62
		AND ticketid = @ticket_id
		AND data = '';
	




		UPDATE htblticketcustomfield
		SET data = @video_card 
		WHERE fieldid = 73 
		AND ticketid = @ticket_id
		AND data = '';
	




		UPDATE htblticketcustomfield
		SET data = @monitor1 
		WHERE fieldid = 74 
		AND ticketid = @ticket_id
		AND data = '';
	



	
		UPDATE htblticketcustomfield
		SET data = @monitor2 
		WHERE fieldid = 76 
		AND ticketid = @ticket_id
		AND data = '';

	END
	ELSE
	BEGIN
		INSERT INTO htblticketcustomfield(ticketid, fieldid, data, tickettypefieldid)
		values (@ticket_id, 65, @login_name, 91);

		INSERT INTO htblticketcustomfield(ticketid, fieldid, data, tickettypefieldid)
		values (@ticket_id, 68, @physical_computer, 84);

		INSERT INTO htblticketcustomfield(ticketid, fieldid, data, tickettypefieldid)
		values (@ticket_id, 75, @office, 88);

		INSERT INTO htblticketcustomfield(ticketid, fieldid, data, tickettypefieldid)
		values (@ticket_id, 61, @virtual_computer, 85);

		INSERT INTO htblticketcustomfield(ticketid, fieldid, data, tickettypefieldid)
		values (@ticket_id, 62, @host, 86);

		INSERT INTO htblticketcustomfield(ticketid, fieldid, data, tickettypefieldid)
		values (@ticket_id, 73, @video_card, 89);

		INSERT INTO htblticketcustomfield(ticketid, fieldid, data, tickettypefieldid)
		values (@ticket_id,74, @monitor1, 87);

		INSERT INTO htblticketcustomfield(ticketid, fieldid, data, tickettypefieldid)
		values (@ticket_id, 76, @monitor2, 90);
	END
END
