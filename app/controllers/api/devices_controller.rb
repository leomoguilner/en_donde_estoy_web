class Api::DevicesController < ApplicationController
	##
  # Crea un dispositivo nuevo. 
  #
  # @resource /api/devices/create
  # @action POST
  #
  # @required [string] name Nombre del dispositivo.
  # @required [integer] category_id 
  # @required [integer] type_id 
  # @optional [text] description Descripcion del device. 
  #
  # @response_field [string] message String con el resultado del metodo.
  # @response_field [string] code numero que representa el resultado del request. 
  #   <ul>
  #      <li><strong>000</strong> SUCCESS </li>
  #      <li><strong>405</strong> No se pudo encontrar la categoria o el tipo. </li>
  #      <li><strong>600</strong> El nombre ya existe. </li>
  #      <li><strong>603</strong> Parametros incorrectos. </li>
  #      <li><strong>999</strong> ERROR </li>
  #   </ul>
  # @example_request 
  #   $.ajax({ type: 'POST', url: "/api/devices/create", data: {name: "Garrahan", description: "Hospital de ninios", category_id: 1, type_id: 1} })
  # @example_response 
  #   {"message":"Device was created successfuly.","code":"600"}
  #
  def create
    if params[:name].blank? or params[:category_id].blank? or params[:type_id].blank?
      response = { :code => "603", :message => "Please, check data you are sending. There is data mising." }    
    else
      device = Device.new :name => params[:name], :description => (params[:description].nil? ? "" : params[:description])
      if device.valid?
        location = Location.new
        location.location_category = LocationCategory.find(params[:category_id])
        location.location_type = LocationType.find(params[:type_id])
        location.device = device
        location.save
        response = { :message => 'Device was created successfuly.', :code => "000" }
      else
        response = { :message => 'Device name has already been taken.', :code => "600" }
      end
    end  
    render json: response
  rescue ActiveRecord::RecordNotFound => e
    render json: { :message => "#{e}", :code => "405" }
  rescue Exception => e
    render json: { :message => 'There was an error while processing this request.', :code => "999" }
  end

  ##
  # Actualiza la posición actual de un dispositivo.
  # 
  # @resource /api/devices/:id/update_location
  # @action PUT
  #
  # @required [integer] latitude Nueva latitud del dispositivo.
  # @required [integer] longitud Nueva longitud del dispositivo.
  # @required [integer] id ID del dispositivo al que vamos a actualizar la posicion actual. Tener en cuenta que viene por url este parametro. 
  #
  # @response_field [string] message String con el resultado del metodo.
  # @response_field [string] code numero que representa el resultado del request. 
  #   <ul>
  #      <li><strong>000</strong> SUCCESS </li>
  #      <li><strong>405</strong> No se encontro el dispositivo. </li>
  #      <li><strong>603</strong> Faltan parametros. </li>
  #      <li><strong>999</strong> ERROR </li>
  #   </ul>
  # @example_request 
  #   $.ajax({ type: 'PUT', url: "/api/devices/1/update_location", data: { latitude: 25.5, longitude: 35 } })
  # @example_response 
  #   {"message":"Updated sucessfully.","code":"000"}
  #
  def update_location
    if params[:latitude].blank? or params[:longitude].blank?
      render json: { :code => "603", :message => "Please, check data you are sending. There are missing params." }    
    else
      device = Device.where(:name => params[:id]).first

      location = device.location
      location_point = LocationPoint.new :latitude => params[:latitude], :longitude => params[:longitude]
      location_point.location = location
      location_point.device = device
      location_point.save
      location.current_location_point = location_point
      location.save

      render json: { :message => 'Updated sucessfully.', :code => "000" }
    end
  rescue ActiveRecord::RecordNotFound
    render json: { :message => 'Could not find device.', :code => "405" }
  rescue Exception => e
    render json: { :message => 'There was an error while trying to update this location.', :code => "999" }
  end  
end